class AddCssPropertyEnum < ActiveRecord::Migration[7.0]
  def change
    add_enum_value :field_type, "css_property"
  end
end
