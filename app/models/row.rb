# == Schema Information
#
# Table name: rows
#
#  id                :uuid             not null, primary key
#  anonymous_tag     :string
#  geo_area          :decimal(, )
#  geo_lat_max       :decimal(, )
#  geo_lat_min       :decimal(, )
#  geo_length        :decimal(, )
#  geo_lng_max       :decimal(, )
#  geo_lng_min       :decimal(, )
#  geojson           :text
#  geom_web_mercator :geometry         geometry, 0
#  line_string       :geometry         linestring, 4326
#  point             :geometry         point, 4326
#  polygon           :geometry         polygon, 4326
#  values            :jsonb            not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  author_id         :uuid
#  feature_id        :bigint           not null
#  layer_id          :uuid             not null
#  territory_id      :uuid
#
# Indexes
#
#  index_rows_on_anonymous_tag            (anonymous_tag)
#  index_rows_on_author_id                (author_id)
#  index_rows_on_created_at               (created_at)
#  index_rows_on_geom_web_mercator        (geom_web_mercator) USING gist
#  index_rows_on_layer_id_and_feature_id  (layer_id,feature_id) UNIQUE
#  index_rows_on_territory_id             (territory_id)
#  index_rows_on_updated_at               (updated_at)
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
  belongs_to :author, optional: true, class_name: "User", inverse_of: :rows
  belongs_to :territory, optional: true

  # Through relations
  has_one :map, through: :layer, inverse_of: :rows

  # Hooks
  after_create_commit -> { broadcast_i18n_append_to map, target: dom_id(layer, :rows), html: render(extra_class: "layer-table__tr--transition layer-table__tr--created") }
  after_update_commit -> { broadcast_i18n_replace_to layer.map, html: render }
  after_destroy_commit -> { broadcast_remove_to layer.map }

  after_commit :after_geometry_changed, on: [:create, :update, :destroy]

  # Dynamic Fields Associations
  include FieldValuesAssociations::RowAssociations

  # Validations
  before_validation :take_first_of_geometry_collection
  validate :validate_geometry_presence
  validate :validate_geometry
  validate :either_author_or_anonymous

  # We use postgis functions to convert to geojson
  # This makes the load be on postgres’ side, not rails (C implementation)
  # We also compute the bounding box
  # The coalesce function takes the first non null value, allowing the same behaviour for each geometry type
  # We are guaranteed that this works, as we have the constraint "num_nonnulls(point, line_string, polygon, territory_id) = 1"
  scope :with_territory, -> do
    left_outer_joins(:territory)
      .select(<<-SQL.squish
      rows.id, layer_id, author_id, anonymous_tag,
      line_string,  
      point,
      polygon,
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

  # Preload all the fields values
  # @layer must be specified: in theory, a query of Rows could be for several layers.
  # In practice, this is to be used to load the rows of a specific layer and preload dynamic associations.
  scope :with_fields_values, ->(layer) do
    with_attached_files.with_territory.includes(:territory, *layer.fields_association_names)
  end

  def author=(user)
    if user.anonymous?
      self.anonymous_tag = user.anonymous_tag
    else
      super
    end
  end

  # Reload self with the fields values (and additional associations)
  def reload_with_fields_values(*additional_includes)
    relation = layer.rows_with_fields_values
    relation = relation.includes(additional_includes) if additional_includes.present?
    relation.find(id)
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
    # Filter invalid field IDs and locked fields
    filtered_values = new_fields_values.filter do |field_id, _value|
      field = layer.fields_by_id[field_id]
      field.present? && !field.locked?
    end

    # Cast values
    casted_values = filtered_values.to_h do |field_id, value|
      field = layer.fields.find(field_id)

      if field.type_files?
        # Create blobs for Files fields
        new_blob_ids = if value.is_a?(Array) && value.each { _1.is_a? ActionDispatch::Http::UploadedFile }
          # Note: refactor file import to properly support addition / removal.
          # value should be an array of existing blob ids and new ActionDispatch::Http::UploadedFile.
          # We also wouldn’t have to rely in the existing value and this code could be moved to Field#cast
          value.map { |file|
            blob = ActiveStorage::Blob.create_and_upload!(
              io: file,
              filename: file.original_filename,
              content_type: file.content_type
            )
            # Rails 7.1 `attach(value) will return the blob and we won’t need to create it separately
            files.attach(blob)
            blob.id
          }
        else
          []
        end
        existing_blob_ids = values[field_id] || []
        value = existing_blob_ids + new_blob_ids
      end

      [field_id, field.cast(value)]
    end

    # Keep other values intact
    values.update(casted_values)
  end

  # Setter to the correct geometry attribute (row.point, row.line_string or row.polygon)
  def geometry=(new_geometry)
    self[layer.geometry_type] = new_geometry
  end

  def geometry
    self[layer.geometry_type]
  end

  def geojson=(new_geojson)
    raise "Can not set the geojson of a territory" if layer.geometry_territory?

    self.geometry = RGeo::GeoJSON.decode(new_geojson, geo_factory: RGEO_FACTORY)
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

  # We round to 4 digits because of testing issues 🤷
  # Depending on the architecture, floats can be different
  # A precision down to a milimeter should be enough
  def calculated_properties
    case layer.geometry_type
    when "line_string"
      {calculated_length: geo_length.to_f.round(3)}
    when "polygon", "territory"
      {calculated_area: geo_area.to_f.round(3)}
    else
      {}
    end
  end

  def render(**kwargs)
    row = reload_with_fields_values(layer: :fields)
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

  def either_author_or_anonymous
    errors.add(:anonymous_tag, :present) if author_id.present? && anonymous_tag.present?
    errors.add(:anonymous_tag, :blank) if author_id.blank? && anonymous_tag.blank?
  end

  def files_by_field(field)
    files_by_id = files.index_by { |file| file.blob_id }
    if field.type_files?
      blob_ids = values[field.id] || []
      blob_ids.map { |blob_id| files_by_id[blob_id] }
    else
      raise "Field #{field.id} is not an file"
    end
  end

  def validate_geometry_presence
    return if layer.geometry_territory?

    if geometry.nil?
      errors.add(:geometry, :required)
    end
  end

  def validate_geometry
    return if layer.geometry_territory?
    return if geometry.nil?

    # Geometry attributes are RGeo types; we can rely on its validity checks.
    # Invalid reasons are defined in RGeo::Error
    unless geometry&.valid?
      errors.add(:geometry, :invalid, reason: geometry.invalid_reason)
    end
  end

  def take_first_of_geometry_collection
    # Note: A Collection geometry of only one feature is invalid for RGeo; this method is called before validation.
    if geometry.is_a? RGeo::Feature::GeometryCollection
      if geometry.size > 1
        warnings.add(:geometry, :multiple_items)
      end
      self.geometry = geometry.first
    end
  end

  def after_geometry_changed
    if previous_changes.key?(layer.geometry_type)
      broadcast_i18n_append_to layer.map, target: dom_id(layer, :updates), partial: "layers/update", locals: {layer_id: layer_id}
    end
  end
end
