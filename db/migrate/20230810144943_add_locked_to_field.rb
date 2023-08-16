class AddLockedToField < ActiveRecord::Migration[7.0]
  def change
    add_column :fields, :locked, :boolean, default: false, null: false
  end
end
