class AddTextIsLarge < ActiveRecord::Migration[7.0]
  def change
    add_column :fields, :text_is_long, :boolean, default: false, null: false
  end
end
