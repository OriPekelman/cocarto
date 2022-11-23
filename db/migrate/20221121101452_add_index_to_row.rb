class AddIndexToRow < ActiveRecord::Migration[7.0]
  def change
    add_index :rows, :updated_at
    add_index :rows, :created_at
  end
end
