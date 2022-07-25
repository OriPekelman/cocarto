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
#  layer_id     :uuid
#  territory_id :uuid
#
# Indexes
#
#  index_rows_on_layer_id      (layer_id)
#  index_rows_on_territory_id  (territory_id)
#
# Foreign Keys
#
#  fk_rails_...  (territory_id => territories.id)
#
class Row < ApplicationRecord
  belongs_to :layer
  belongs_to :territory, -> { with_geojson }, inverse_of: :rows, optional: true

  after_update_commit -> do
    broadcast_replace_to layer, partial: "rows/row_rw", locals: {row: self}
    broadcast_replace_to "#{layer.id}_ro", partial: "rows/row_ro", locals: {row: self}
  end
  after_destroy_commit -> do
    broadcast_remove_to layer
    broadcast_remove_to "#{layer.id}_ro"
  end
  after_create_commit -> do
    broadcast_append_to layer, target: "rows-tbody", partial: "rows/row_rw", locals: {row: self}
    broadcast_append_to "#{layer.id}_ro", target: "rows-tbody", partial: "rows/row_ro", locals: {row: self}
    broadcast_replace_to layer, target: "tutorial", partial: "layers/tooltip", locals: {layer: layer}
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

  def geometry
    self[layer.geometry_type]
  end

  # Geometry accessor, as geojson (used in the row form)
  def geojson
    if layer.geometry_territory?
      row.territory.geojson
    else
      RGeo::GeoJSON.encode(geometry).to_json
    end
  end

  def geojson=(new_geojson)
    raise "Can not set the geojson of a territory" if layer.geometry_territory?
    self.geometry = RGeo::GeoJSON.decode(new_geojson, geo_factory: RGEO_FACTORY)
  end

  # Geojson export (used when exporting a layer as json)
  def geo_feature
    RGeo::GeoJSON::Feature.new(geometry, nil, geo_properties)
  end

  def geo_properties
    layer.fields.to_h { |field| [field.label, values[field.id]] }
  end

  def self.bbox
    reorder(nil).select("st_xmin(st_union(point)) as xmin,
    st_xmax(st_union(point)) as xmax,
    st_ymin(st_union(point)) as ymin,
    st_ymax(st_union(point)) as ymax")[0]
  end
end
