class AddLineStringToRow < ActiveRecord::Migration[7.0]
  def change
    rename_enum_value :geometry_type_enum, :linestring, :line_string
    add_column :rows, :line_string, :line_string, srid: 4326
  end
end
