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
  has_many_attached :files

  # Relations
  belongs_to :layer, touch: true
  belongs_to :author, class_name: "User", inverse_of: :rows
  belongs_to :territory, optional: true

  # Through relations
  has_one :map, through: :layer, inverse_of: :rows

  # Hooks
  after_update_commit -> { broadcast_i18n_replace_to layer.map, html: render }
  after_destroy_commit -> { broadcast_remove_to layer.map }
  after_create_commit -> { broadcast_i18n_append_to map, target: dom_id(layer, :rows), html: render(extra_class: "layer-table__tr--transition layer-table__tr--created") }

  # Dynamic Fields Associations
  include FieldValuesAssociations::RowAssociations

  # Validations
  validate :validate_geometry

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
      if field.type_territory?
        value = association(field.association_name).reader
      elsif field.type_files?
        value = files_by_field(field)
      end
      [field, value]
    end
  end

  def fields_values=(new_fields_values)
    cleaned_values = layer.fields.to_h do |field|
      value = new_fields_values[field.id]

      if field.type_files? && value.present?
        new_blob_ids = value.map { |file|
          blob = ActiveStorage::Blob.create_and_upload!(
            io: file,
            filename: file.original_filename,
            content_type: file.content_type
          )
          # Rails 7.1 `attach(value) will return the blob and we won’t need to create it separately
          files.attach(blob)
          blob.id
        }
        existing_blob_ids = values[field.id] || []
        value = existing_blob_ids + new_blob_ids
      end

      [field.id, field.cast(value)]
    end

    self.values = cleaned_values
  end

  # Accessor to the correct geometry attribute (row.point, row.line_string or row.polygon)
  def geometry=(new_geometry)
    self[layer.geometry_type] = new_geometry
  end

  def geojson=(new_geojson)
    raise "Can not set the geojson of a territory" if layer.geometry_territory?

    begin
      # raises if the geometry is not valid
      # e.g. bowtie polygon
      # While such a geometry is a valid geojson,
      # it’s not a valid OGC geometry.
      # Hence we reject it.
      self.geometry = RGeo::GeoJSON.decode(new_geojson, geo_factory: RGEO_FACTORY)
    rescue => e
      @geojson_error = e
    end
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

  def render(**kwargs)
    row = Row.with_attached_files.with_territory.includes(:territory, *layer.fields_association_names, layer: :fields).find(id)
    ApplicationController.render(RowComponent.new(row: row, **kwargs), layout: false)
  end

  def bounding_box
    [geo_lng_min, geo_lat_min, geo_lng_max, geo_lat_max]
  end

  def self.bounding_box
    left_outer_joins(:territory)
      .select(<<-SQL.squish
    min(COALESCE(rows.geo_lng_min, territories.geo_lng_min)) as geo_lng_min,
    min(COALESCE(rows.geo_lat_min, territories.geo_lat_min)) as geo_lat_min,
    max(COALESCE(rows.geo_lng_max, territories.geo_lng_max)) as geo_lng_max,
    max(COALESCE(rows.geo_lat_max, territories.geo_lat_max)) as geo_lat_max
    SQL
             )[0].values_at("geo_lng_min", "geo_lat_min", "geo_lng_max", "geo_lat_max")
  end

  private

  def files_by_field(field)
    files_by_id = files.index_by { |file| file.blob_id }
    if field.type_files?
      blob_ids = values[field.id] || []
      blob_ids.map { |blob_id| files_by_id[blob_id] }
    else
      raise "Field #{field.id} is not an file"
    end
  end

  def validate_geometry
    if @geojson_error
      if @geojson_error.is_a? RGeo::Error::InvalidGeometry
        errors.add(:geojson, :invalid_geometry)
      elsif @geojson_error.is_a? JSON::ParserError
        errors.add(:geojson, :invalid_json)
      else
        errors.add(:geojson, @geojson_error.message)
      end
    end
  end
end
