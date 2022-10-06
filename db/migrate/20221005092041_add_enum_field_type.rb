class AddEnumFieldType < ActiveRecord::Migration[7.0]
  def change
    add_enum_value :field_type, "enum"
    add_column :fields, :enum_values, :string, array: true
  end
end
