class ChangeTerritories < ActiveRecord::Migration[7.0]
  def change
    change_table :territories do |t|
      execute <<-SQL
        ALTER TABLE territories
        ALTER COLUMN geography SET DATA TYPE geometry(MultiPolygon, 4326)
        USING geography::geometry(MultiPolygon, 4326);
      SQL
      t.rename :geography, :geometry
      t.column :code, :string
      t.index [:code, :territory_category_id], unique: true
    end

    add_index :territory_categories, [:name, :revision], unique: true
  end
end
