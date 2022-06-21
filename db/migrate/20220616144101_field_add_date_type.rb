class FieldAddDateType < ActiveRecord::Migration[7.0]
  def up
    add_enum_value :fields_type_enum, "date"
  end

  def down
    remove_enum_value :fields_type_enum, "date"
  end
end
