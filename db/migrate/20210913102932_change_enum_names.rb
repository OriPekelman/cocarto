class ChangeEnumNames < ActiveRecord::Migration[6.1]
  def change
    rename_enum :attribute_type, :attribute_type_enum
    rename_enum :product_type, :geometry_type_enum
  end
end
