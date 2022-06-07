class ChangeTerritories < ActiveRecord::Migration[7.0]
  def change
    change_table :territories do |t|
      # A territory can have islands. Hence it is as MultiPolygon, not a polygon
      # We need an SQL request to use a explicit `USING` to cast the polygon
      # We switch from geography to geometry. Geography handles implicitly that the earth is round
      # …but this yields more problems as only few functions are aware that the earth is round
      # This is not revertable, but we haven’t any actual user yet. Yolo.
      execute <<-SQL.squish
        ALTER TABLE territories
        ALTER COLUMN geography SET DATA TYPE geometry(MultiPolygon, 4326)
        USING geography::geometry(MultiPolygon, 4326);
      SQL
      t.rename :geography, :geometry

      # This adds an extra column code that is the official id within a territory_category
      # Within that category, the code must be unique
      t.column :code, :string
      t.index [:code, :territory_category_id], unique: true
    end

    # We add a constraint so that there can only be one category name for a given revision
    # It won’t be possible to have two Countries(2022)
    # Having divergent visions requires a different revision Countries(2022-seen-from-russia)
    add_index :territory_categories, [:name, :revision], unique: true
  end
end
