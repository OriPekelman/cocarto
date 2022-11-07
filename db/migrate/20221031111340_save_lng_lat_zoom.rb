class SaveLngLatZoom < ActiveRecord::Migration[7.0]
  def change
    add_column :maps, :default_latitude, :float
    add_column :maps, :default_longitude, :float
    add_column :maps, :default_zoom, :float
  end
end
