class AddCalculatedWebmercatorGeom < ActiveRecord::Migration[7.0]
  def change
    change_table :rows do |t|
      t.virtual :geom_web_mercator,
        type: :geometry,
        as: "ST_Transform( COALESCE(point, line_string, polygon), 3857 )",
        stored: true
      t.index :geom_web_mercator, using: :gist
    end

    change_table :territories do |t|
      t.virtual :geom_web_mercator,
        type: :geometry,
        as: "ST_Transform( geometry, 3857 )",
        stored: true
      t.index :geom_web_mercator, using: :gist
    end
  end
end
