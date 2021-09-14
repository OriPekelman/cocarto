class RenameAttributesToField < ActiveRecord::Migration[6.1]
  def change
    rename_table :attributes, :fields
    rename_column :points, :attributes, :fields
    rename_enum :attribute_type_enum, :fields_type_enum
  end
end
