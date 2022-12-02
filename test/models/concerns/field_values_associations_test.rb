require "test_helper"

class FieldValuesAssociationsTest < ActiveSupport::TestCase
  test "eager_loading fields_association_names builds the associations" do
    layer = layers(:restaurants)
    rows = layer.rows.eager_load(layer.fields_association_names)

    assert_equal territories(:paris), rows.first.association(fields(:restaurant_ville).association_name).target
    assert_equal rows.first, rows.first.association(fields(:restaurant_ville).association_name).owner
  end

  test "preloading fields_association_names builds the associations" do
    layer = layers(:restaurants)
    rows = layer.rows.preload(layer.fields_association_names)

    assert_equal territories(:paris), rows.first.association(fields(:restaurant_ville).association_name).target
    assert_equal rows.first, rows.first.association(fields(:restaurant_ville).association_name).owner
  end
end
