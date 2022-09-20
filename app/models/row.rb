# == Schema Information
#
# Table name: rows
#
#  id           :uuid             not null, primary key
#  line_string  :geometry         linestring, 4326
#  point        :geometry         point, 4326
#  polygon      :geometry         polygon, 4326
#  values       :jsonb            not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  author_id    :uuid
#  layer_id     :uuid
#  territory_id :uuid
#
# Indexes
#
#  index_rows_on_author_id     (author_id)
#  index_rows_on_layer_id      (layer_id)
#  index_rows_on_territory_id  (territory_id)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (layer_id => layers.id)
#  fk_rails_...  (territory_id => territories.id)
#
class Row < ApplicationRecord
  belongs_to :layer
  belongs_to :author, class_name: "User"
  belongs_to :territory, -> { with_geojson }, inverse_of: :rows, optional: true

  after_update_commit -> { broadcast_replace_to layer, object: Row.with_geom.find(id) }
  after_destroy_commit -> { broadcast_remove_to layer }
  after_create_commit -> { broadcast_append_to layer, target: "rows-tbody", object: Row.with_geom.find(id) }

  # We use postgis functions to convert to geojson
  # This makes the load be on postgres’ side, not rails (C implementation)
  # We also compute the bounding box
  # The coalesce function takes the first non null value, allowing the same behaviour for each geometry type
  # We are guaranteed that this works, as we have the constraint "num_nonnulls(point, line_string, polygon, territory_id) = 1"
  scope :with_geom, -> do
    left_outer_joins(:territory)
      .select(<<-SQL.squish
      rows.*,
      st_asgeojson(COALESCE(point, line_string, polygon, territories.geometry)) as geojson,
      st_Xmin(COALESCE(point, line_string, polygon, territories.geometry)) as lng_min,
      st_Ymin(COALESCE(point, line_string, polygon, territories.geometry)) as lat_min,
      st_Xmax(COALESCE(point, line_string, polygon, territories.geometry)) as lng_max,
      st_Ymax(COALESCE(point, line_string, polygon, territories.geometry)) as lat_max,
      st_length(line_string::geography) as length,
      st_area(polygon::geography) as area
    SQL
             )
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
      if field.territory?
        value = Territory.find_by(id: value)
      end
      [field, value]
    end
  end

  def fields_values=(new_fields_values)
    cleaned_values = layer.fields.to_h do |field|
      value = new_fields_values[field.id]
      if field.territory?
        value = Territory.exists?(id: value) ? value : nil
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
    RGeo::GeoJSON::Feature.new(feature, id, geo_properties)
  end

  def geo_properties
    layer.fields.to_h { |field| [field.label, values[field.id]] }
  end
end
