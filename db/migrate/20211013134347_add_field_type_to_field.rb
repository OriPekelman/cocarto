class AddFieldTypeToField < ActiveRecord::Migration[6.1]
  def change
    add_column :fields, :field_type, :fields_type_enum
  end
end
