# == Schema Information
#
# Table name: rows
#
#  id          :uuid             not null, primary key
#  line_string :geometry         linestring, 4326
#  point       :geometry         point, 4326
#  polygon     :geometry         polygon, 4326
#  values      :jsonb            not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  layer_id    :uuid
#
# Indexes
#
#  index_rows_on_layer_id  (layer_id)
#
class Row < ApplicationRecord
  belongs_to :layer
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

  # Iterates of each field with its data
  def data
    layer.fields.each do |field|
      value = values[field.id]
      if field.field_type == "territory" && !value.nil?
        value = Territory.find(value)
      end
      yield [field, value]
    end
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
    RGeo::GeoJSON.encode(geometry).to_json
  end

  def geojson=(new_geojson)
    self.geometry = RGeo::GeoJSON.decode(new_geojson, geo_factory: RGEO_FACTORY)
  end

  # Geojson export (used when exporting a layer as json)
  def geo_feature
    RGeo::GeoJSON::Feature.new(geometry, nil, geo_properties)
  end

  def geo_properties
    layer.fields.map { |field| [field.label, values[field.id]] }.to_h
  end
end
