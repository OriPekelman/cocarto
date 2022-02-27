class AddPointToRowContents < ActiveRecord::Migration[7.0]
  def up
    # Before we had one table for the attributes, and 3 tables for the geometry
    # This implied polymorphic relationships
    # It will be much simpler if we just have one table, with 3 mutually exclusive columns
    # So far, we only hande points
    add_column :row_contents, :point, :st_point, geography: true

    # Oups, we forgot that one earlier
    add_timestamps :row_contents, default: -> { 'CURRENT_TIMESTAMP' }

    RowContent.all.each do |r|
      p = Point.find(r.geometry_id)
      r.point = p.geog
      r.save!
    end

    # Remove the complicated relationships management
    remove_columns(:row_contents, :geometry_id, :geometry_type)


    # Tada, this table is no longer needed
    drop_table :points
  end

  def down
    add_belongs_to :row_contents, :geometry, polymorphic: true, type: :uuid

    create_table :points,  id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.st_point :geog, geography: true
      t.references :layer, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    RowContent.all.each do |r|
      p = Point.create(geog: r.point, layer_id: r.layer_id)
      r.geometry = p
      r.save!
    end

    remove_column :row_contents, :point
    remove_timestamps :row_contents
  end
end
