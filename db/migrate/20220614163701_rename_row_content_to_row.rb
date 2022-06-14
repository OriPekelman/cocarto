class RenameRowContentToRow < ActiveRecord::Migration[7.0]
  def change
    rename_table :row_contents, :rows
  end
end
