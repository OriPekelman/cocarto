# == Schema Information
#
# Table name: fields
#
#  id          :uuid             not null, primary key
#  enum_values :string           is an Array
#  field_type  :enum             not null
#  label       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  layer_id    :uuid             not null
#
# Indexes
#
#  index_fields_on_layer_id  (layer_id)
#
# Foreign Keys
#
#  fk_rails_...  (layer_id => layers.id)
#
require "test_helper"

class FieldTest < ActiveSupport::TestCase
  class EnumFieldTest < FieldTest
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
  end
end
