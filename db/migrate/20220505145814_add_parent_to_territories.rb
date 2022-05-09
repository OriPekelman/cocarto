class AddParentToTerritories < ActiveRecord::Migration[7.0]
  def change
    add_column :territories, :parent_id, :uuid
    add_foreign_key :territories, :territories, column: :parent_id
  end
end
