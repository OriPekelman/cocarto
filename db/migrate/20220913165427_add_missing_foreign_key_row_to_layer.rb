class AddMissingForeignKeyRowToLayer < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :rows, :layers
  end
end
