# == Schema Information
#
# Table name: rows
#
#  id           :uuid             not null, primary key
#  geo_area     :decimal(, )
#  geo_lat_max  :decimal(, )
#  geo_lat_min  :decimal(, )
#  geo_length   :decimal(, )
#  geo_lng_max  :decimal(, )
#  geo_lng_min  :decimal(, )
#  geojson      :text
#  line_string  :geometry         linestring, 4326
#  point        :geometry         point, 4326
#  polygon      :geometry         polygon, 4326
#  values       :jsonb            not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  author_id    :uuid             not null
#  layer_id     :uuid             not null
#  territory_id :uuid
#
# Indexes
#
#  index_rows_on_author_id     (author_id)
#  index_rows_on_created_at    (created_at)
#  index_rows_on_layer_id      (layer_id)
#  index_rows_on_territory_id  (territory_id)
#  index_rows_on_updated_at    (updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (layer_id => layers.id)
#  fk_rails_...  (territory_id => territories.id)
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
      antipode = rows("antipode")

      antipode_from_db = layers("restaurants").rows.includes(layers("restaurants").fields_association_names).find(antipode.id)
      assert_equal territories("paris"), antipode_from_db.fields_values[field("Ville")]
    end

    test "invalid territory identifier is ignored" do
      antipode = rows("antipode")
      antipode.fields_values = {field("Ville").id => "invalid identifier"}
      antipode.save!

      antipode_from_db = layers("restaurants").rows.includes(layers("restaurants").fields_association_names).find(antipode.id)
      assert_nil antipode_from_db.fields_values[field("Ville")]
    end

    # Set values from user input
    test "value is saved" do
      row = Row.new(layer: layer)
      row.assign_attributes(fields_values: {field("Name").id => "Le Bastringue"})
      assert_equal "Le Bastringue", row.values[field("Name").id]
    end

    test "invalid field identifier is not saved" do
      row = Row.new(layer: layer)
      row.assign_attributes(fields_values: {invalid_field_identifier: "whatever"})
      assert_nil row.values[:invalid_field_identifier]
    end

    test "valid territory id is saved" do
      row = Row.new(layer: layer)
      row.assign_attributes(fields_values: {field("Ville").id => territories("paris").id})
      assert_equal territories("paris").id, row.values[field("Ville").id]
    end

    test "invalid territory id is ignored" do
      row = Row.new(layer: layer)
      row.assign_attributes(fields_values: {field("Ville").id => "invalid_identifier"})
      assert_nil row.values[field("Ville").id]
    end
  end
end
