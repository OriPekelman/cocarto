class FieldAddCheckedBooleanType < ActiveRecord::Migration[7.0]
  def up
    add_enum_value :fields_type_enum, "boolean"
  end

  def down
    remove_enum_value :fields_type_enum, "boolean"
  end
end
