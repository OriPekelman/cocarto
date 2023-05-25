class RowFeatureIdAsInteger < ActiveRecord::Migration[7.0]
  def change
    add_column :rows, :feature_id, :bigserial
    add_index :rows, [:layer_id, :feature_id], unique: true
    # https://github.com/gregnavis/active_record_doctor#removing-extraneous-indexes
    remove_index :rows, :layer_id, name: "index_rows_on_layer_id"
  end
end
