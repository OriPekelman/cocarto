class AddVirtualColumnsToRowsAndTerritories < ActiveRecord::Migration[7.0]
  def change
    change_table :rows do |t|
      t.virtual :geojson, type: :text, as: "st_asgeojson(COALESCE(point, line_string, polygon))", stored: true
      t.virtual :geo_lng_min, type: :numeric, as: "st_Xmin(COALESCE(point, line_string, polygon))", stored: true
      t.virtual :geo_lat_min, type: :numeric, as: "st_Ymin(COALESCE(point, line_string, polygon))", stored: true
      t.virtual :geo_lng_max, type: :numeric, as: "st_Xmax(COALESCE(point, line_string, polygon))", stored: true
      t.virtual :geo_lat_max, type: :numeric, as: "st_Ymax(COALESCE(point, line_string, polygon))", stored: true
      t.virtual :geo_length, type: :numeric, as: "st_length(line_string::geography)", stored: true
      t.virtual :geo_area, type: :numeric, as: "st_area(polygon::geography)", stored: true
    end

    change_table :territories do |t|
      t.virtual :geojson, type: :text, as: "st_asgeojson(geometry)", stored: true
      t.virtual :geo_lng_min, type: :numeric, as: "st_Xmin(geometry)", stored: true
      t.virtual :geo_lat_min, type: :numeric, as: "st_Ymin(geometry)", stored: true
      t.virtual :geo_lng_max, type: :numeric, as: "st_Xmax(geometry)", stored: true
      t.virtual :geo_lat_max, type: :numeric, as: "st_Ymax(geometry)", stored: true
      t.virtual :geo_area, type: :numeric, as: "st_area(geometry::geography)", stored: true
    end
  end
end
