# == Schema Information
#
# Table name: rows
#
#  id           :uuid             not null, primary key
#  geo_area     :decimal(, )
#  geo_lat_max  :decimal(, )
#  geo_lat_min  :decimal(, )
#  geo_length   :decimal(, )
#  geo_lng_max  :decimal(, )
#  geo_lng_min  :decimal(, )
#  geojson      :text
#  line_string  :geometry         linestring, 4326
#  point        :geometry         point, 4326
#  polygon      :geometry         polygon, 4326
#  values       :jsonb            not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  author_id    :uuid             not null
#  layer_id     :uuid             not null
#  territory_id :uuid
#
# Indexes
#
#  index_rows_on_author_id     (author_id)
#  index_rows_on_created_at    (created_at)
#  index_rows_on_layer_id      (layer_id)
#  index_rows_on_territory_id  (territory_id)
#  index_rows_on_updated_at    (updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (layer_id => layers.id)
#  fk_rails_...  (territory_id => territories.id)
#
class Row < ApplicationRecord
  # Relations
  belongs_to :layer
  belongs_to :author, class_name: "User"
  belongs_to :territory, optional: true

  # Through relations
  has_one :map, through: :layer, inverse_of: :rows

  # Hooks
  after_update_commit -> { broadcast_i18n_replace_to layer.map, object: layer.rows_with_territories.with_territory.includes(:territory, layer: :fields).find(id) }
  after_destroy_commit -> { broadcast_remove_to layer.map }
  after_create_commit -> { broadcast_i18n_append_to map, target: dom_id(layer, "rows"), locals: {extra_class: "highlight-transition bg-transition"}, object: Row.with_territory.includes(:territory, layer: :fields).find(id) }

  # We use postgis functions to convert to geojson
  # This makes the load be on postgres’ side, not rails (C implementation)
  # We also compute the bounding box
  # The coalesce function takes the first non null value, allowing the same behaviour for each geometry type
  # We are guaranteed that this works, as we have the constraint "num_nonnulls(point, line_string, polygon, territory_id) = 1"
  scope :with_territory, -> do
    left_outer_joins(:territory)
      .select(<<-SQL.squish
      rows.id, layer_id, author_id,
      values,
      rows.created_at, rows.updated_at,
      territory_id,
      geo_length,
      COALESCE(rows.geojson, territories.geojson) as geojson,
      COALESCE(rows.geo_area, territories.geo_area) as geo_area,
      COALESCE(rows.geo_lng_min, territories.geo_lng_min) as geo_lng_min,
      COALESCE(rows.geo_lat_min, territories.geo_lat_min) as geo_lat_min,
      COALESCE(rows.geo_lng_max, territories.geo_lng_max) as geo_lng_max,
      COALESCE(rows.geo_lat_max, territories.geo_lat_max) as geo_lat_max
    SQL
             )
  end

  scope :with_territory_column, ->(territory_field) do
    # Warning: column names can only be 63 chars.
    prefixed_columns = Territory
      .attribute_names
      .map { "\"#{territory_field}\".#{_1} AS \"#{territory_field}_#{_1}\"" }
      .join(", ")

    joins("LEFT JOIN territories AS \"#{territory_field}\" ON \"#{territory_field}\".id = (values->>'#{territory_field}')::uuid")
      .select(prefixed_columns)
  end

  # Values accessors:
  # fields_values and fields_values= have two roles
  # - make sure the values in the DB and from user input are for existing fields of the layer
  # - cast values to correct field types (currently only for Territory)
  # NOTE: fields_values and fields_values= are not symmetrical
  # - the getter returns Fields as keys, the setter wants Field ids
  # - the getter returns Territory objects, the setter wants Territory ids
  def fields_values
    db_values = values
    layer.fields.to_h do |field|
      value = db_values[field.id]
      if field.type_territory? && attributes["#{field.id}_id"].present?
        attributes = self.attributes
          .filter { _1.starts_with?(field.id) }
          .transform_keys { _1.delete_prefix("#{field.id}_") }
        value = Territory.new(attributes)
      end
      [field, value]
    end
  end

  def fields_values=(new_fields_values)
    cleaned_values = layer.fields.to_h do |field|
      value = new_fields_values[field.id]
      if field.type_territory?
        value = Territory.exists?(id: value) ? value : nil
      elsif field.type_css_property? && field.label == "stroke-width" && value.present?
        value = value.to_i
      end
      [field.id, value]
    end

    self.values = cleaned_values
  end

  # Accessor to the correct geometry attribute (row.point, row.line_string or row.polygon)
  def geometry=(new_geometry)
    self[layer.geometry_type] = new_geometry
  end

  def geojson=(new_geojson)
    raise "Can not set the geojson of a territory" if layer.geometry_territory?
    self.geometry = RGeo::GeoJSON.decode(new_geojson, geo_factory: RGEO_FACTORY)
  end

  # Geojson export (used when exporting a layer as json)
  def geo_feature
    feature = RGeo::GeoJSON.decode(geojson)
    RGeo::GeoJSON::Feature.new(feature, id, geo_properties.merge(css_properties).merge(calculated_properties))
  end

  def geo_properties
    layer
      .fields
      .reject { |field| field.type_css_property? }
      .to_h { |field| [field.label, values[field.id]] }
  end

  # Properties keys come from https://github.com/mapbox/simplestyle-spec/
  def default_style
    case layer.geometry_type
    when "point" then {"marker-color": layer.color}
    when "line_string" then {stroke: layer.color}
    when "polygon", "territory" then {
      stroke: layer.color,
      fill: layer.color
    }
    end
  end

  def css_properties
    custom_style = layer
      .fields
      .filter { |field| field.type_css_property? }
      .map { |field| [field.label, values[field.id]] }
      .compact_blank
      .to_h
    default_style.merge(custom_style)
  end

  def calculated_properties
    case layer.geometry_type
    when "line_string"
      {calculated_length: geo_length}
    when "polygon", "territory"
      {calculated_area: geo_area}
    else
      {}
    end
  end
end
