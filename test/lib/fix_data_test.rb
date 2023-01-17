require "test_helper"

class FixDataTest < ActiveSupport::TestCase
  test "cast values that were strings" do
    layer = layers(:restaurants)

    text_field = layer.fields.type_text.create
    int_field = layer.fields.type_integer.create
    bool_field = layer.fields.type_boolean.create

    values = {
      text_field.id => "1",
      int_field.id => "1",
      bool_field.id => "1"
    }
    row = layer.rows.create(values: values, author: users(:reclus), point: "POINT(1 1)")

    Cocarto::Application.load_tasks
    Rake::Task["fix_data:fields_values_type"].invoke

    row = Row.find(row.id)

    assert_equal "1", row.values[text_field.id]
    assert_equal 1, row.values[int_field.id]
    assert row.values[bool_field.id]
  end
end
