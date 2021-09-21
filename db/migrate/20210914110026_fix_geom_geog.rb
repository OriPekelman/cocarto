class FixGeomGeog < ActiveRecord::Migration[6.1]
  def change
    rename_column :tables, :geography_type, :geometry_type
    remove_column :attributes, :geography_type
  end
end
