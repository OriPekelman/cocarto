class AddPointToRowContents < ActiveRecord::Migration[7.0]
  def up
    # Before we had one table for the attributes, and 3 tables for the geometry
    # This implied polymorphic relationships
    # It will be much simpler if we just have one table, with 3 mutually exclusive columns
    # So far, we only hande points
    add_column :row_contents, :point, :st_point, geography: true

    # Oups, we forgot that one earlier
    add_timestamps :row_contents, default: -> { "CURRENT_TIMESTAMP" }

    execute <<-SQL
    UPDATE row_contents SET point = point_table.geog
    FROM points AS point_table
    WHERE row_contents.geometry_id = point_table.id
    SQL

    # Remove the complicated relationships management
    remove_columns(:row_contents, :geometry_id, :geometry_type)

    # Tada, this table is no longer needed
    drop_table :points
  end

  def down
    add_belongs_to :row_contents, :geometry, polymorphic: true, type: :uuid

    create_table :points, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.st_point :geog, geography: true
      t.references :layer, null: false, foreign_key: true, type: :uuid
      t.uuid :row_content_id
      t.timestamps
    end

    execute <<-SQL
    WITH new_ids AS (INSERT INTO points (geog, layer_id, created_at, updated_at, row_content_id)
    SELECT point, layer_id, now(), now(), id FROM row_contents
    RETURNING id, row_content_id)

    UPDATE row_contents SET geometry_id = new_ids.id
    FROM new_ids
    WHERE row_contents.id = row_content_id
    SQL

    remove_column :points, :row_content_id
    remove_column :row_contents, :point
    remove_timestamps :row_contents
  end
end
