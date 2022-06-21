class RowCanBePolygon < ActiveRecord::Migration[7.0]
  def change
    change_table :rows do |t|
      t.st_polygon :polygon, srid: 4326
    end
  end
end
