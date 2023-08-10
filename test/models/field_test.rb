# == Schema Information
#
# Table name: fields
#
#  id          :uuid             not null, primary key
#  enum_values :string           is an Array
#  field_type  :enum             not null
#  label       :string
#  sort_order  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  layer_id    :uuid             not null
#
# Indexes
#
#  index_fields_on_layer_id_and_sort_order  (layer_id,sort_order) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (layer_id => layers.id)
#
require "test_helper"

class FieldTest < ActiveSupport::TestCase
  class Base < FieldTest
    test "type can’t be changed" do
      field = layers(:restaurants).fields.type_text.create!

      field.type_integer!

      assert_predicate field, :type_integer?

      field.reload

      assert_predicate field, :type_text?
    end
  end

  class Enum < FieldTest
    test "some enum value is allowed" do
      field = Field.type_enum.new(enum_values: ["value"])
      field.validate

      assert_empty field.errors.details[:enum_values]
    end

    test "several enum values are allowed" do
      field = Field.type_enum.new(enum_values: %w[a b c])
      field.validate

      assert_empty field.errors.details[:enum_values]
    end

    test "no enum value is invalid" do
      field = Field.type_enum.new
      field.validate

      assert_equal [{error: :blank}], field.errors.details[:enum_values]
    end

    test "only blank value is invalid" do
      field = Field.type_enum.new(enum_values: [""])
      field.validate

      assert_equal [{error: :blank}], field.errors.details[:enum_values]
    end

    test "blank enum values are removed" do
      field = Field.type_enum.new(enum_values: ["a", "b", "c", ""])

      assert_equal %w[a b c], field.enum_values
    end

    test "duplicate enum values are removed" do
      field = Field.type_enum.new(enum_values: %w[a b c c])

      assert_equal %w[a b c], field.enum_values
    end

    test "correctly cast strings to booleans" do
      bool_field = Field.type_boolean.new

      assert_includes [true, false], bool_field.cast("1")
      assert_not bool_field.cast("0")
      assert_nil bool_field.cast("")
    end

    test "correctly cast strings to integerss" do
      int_field = Field.type_integer.new

      assert_equal 42, int_field.cast("42")
      assert_nil int_field.cast("")
    end

    test "correctly cast strings to floats" do
      float_field = Field.type_float.new

      assert_in_epsilon 3.14, float_field.cast("3.14")
      assert_nil float_field.cast("")
      assert_nil float_field.cast(nil)
    end

    test "don’t cast fields that don’t need to" do
      enum_field = Field.type_enum.new(enum_values: %w[a b c])

      assert_equal "b", enum_field.cast("b")

      text_field = Field.type_text.new

      assert_equal "hello", text_field.cast("hello")
      assert_equal "", text_field.cast("")
    end

    test "correcly cast css-properties" do
      stroke = Field.type_css_property.new(label: "stroke-width")

      assert_equal 3, stroke.cast("3")
      assert_nil stroke.cast("")

      color = Field.type_css_property.new(label: "color")

      assert_equal "333", color.cast("333")
    end
  end

  class SumTest < FieldTest
    test "Float sum has correct value and type" do
      assert_in_delta(9.0, fields(:restaurant_rating).sum)
      assert_instance_of Float, fields(:restaurant_rating).sum
    end

    test "Integer sum has correct value and type" do
      assert_equal 70, fields(:restaurant_table_size).sum
      assert_instance_of Integer, fields(:restaurant_table_size).sum
    end
  end
end
