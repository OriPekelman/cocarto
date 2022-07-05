class AddColorToLayer < ActiveRecord::Migration[7.0]
  def change
    add_column :layers, :style, :jsonb, null: false, default: {}
  end
end
