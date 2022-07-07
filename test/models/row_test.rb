# == Schema Information
#
# Table name: rows
#
#  id          :uuid             not null, primary key
#  line_string :geometry         linestring, 4326
#  point       :geometry         point, 4326
#  polygon     :geometry         polygon, 4326
#  values      :jsonb            not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  layer_id    :uuid
#
# Indexes
#
#  index_rows_on_layer_id  (layer_id)
#
require "test_helper"

class RowTest < ActiveSupport::TestCase
  class FieldsValuesTest < RowTest
    def layer
      layers("restaurants")
    end

    def field(field_label)
      layer.fields.find_by(label: field_label)
    end

    def restaurant_with_value(field, value)
      layer.rows.new(values: {field.id => value})
    end

    # Read values from DB
    test "value is returned" do
      assert_equal "Le Bastringue", restaurant_with_value(field("Name"), "Le Bastringue").fields_values[field("Name")]
    end

    test "invalid field identifier is filtered" do
      assert_nil layer.rows.new(values: {invalid_field_identifier: "whatever"}).fields_values[:invalid_field_identifier]
    end

    test "territory value is returned as Territory object" do
      assert_equal territories("paris"), restaurant_with_value(field("Ville"), territories("paris").id).fields_values[field("Ville")]
    end

    test "invalid territory identifier is ignored" do
      assert_nil restaurant_with_value(field("Ville"), "invalid_identifier").fields_values[field("Ville")]
    end
  end
end
