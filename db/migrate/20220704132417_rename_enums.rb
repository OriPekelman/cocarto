class RenameEnums < ActiveRecord::Migration[7.0]
  def change
    rename_enum :fields_type_enum, :field_type
    rename_enum :geometry_type_enum, :layer_geometry_type
  end
end
