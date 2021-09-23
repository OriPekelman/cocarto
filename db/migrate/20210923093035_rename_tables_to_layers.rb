class RenameTablesToLayers < ActiveRecord::Migration[6.1]
  def change
    rename_table :tables, :layers
    rename_column :points, :table_id, :layer_id
    rename_column :fields, :table_id, :layer_id
  end
end
