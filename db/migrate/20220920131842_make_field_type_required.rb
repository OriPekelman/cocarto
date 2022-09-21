class MakeFieldTypeRequired < ActiveRecord::Migration[7.0]
  def change
    change_column_null :fields, :field_type, false
  end
end
