# == Schema Information
#
# Table name: rows
#
#  id                :uuid             not null, primary key
#  anonymous_tag     :string
#  geo_area          :decimal(, )
#  geo_lat_max       :decimal(, )
#  geo_lat_min       :decimal(, )
#  geo_length        :decimal(, )
#  geo_lng_max       :decimal(, )
#  geo_lng_min       :decimal(, )
#  geojson           :text
#  geom_web_mercator :geometry         geometry, 0
#  line_string       :geometry         linestring, 4326
#  point             :geometry         point, 4326
#  polygon           :geometry         polygon, 4326
#  values            :jsonb            not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  author_id         :uuid
#  feature_id        :bigint           not null
#  layer_id          :uuid             not null
#  territory_id      :uuid
#
# Indexes
#
#  index_rows_on_anonymous_tag            (anonymous_tag)
#  index_rows_on_author_id                (author_id)
#  index_rows_on_created_at               (created_at)
#  index_rows_on_geom_web_mercator        (geom_web_mercator) USING gist
#  index_rows_on_layer_id_and_feature_id  (layer_id,feature_id) UNIQUE
#  index_rows_on_territory_id             (territory_id)
#  index_rows_on_updated_at               (updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => users.id)
#  fk_rails_...  (layer_id => layers.id)
#  fk_rails_...  (territory_id => territories.id)
#
require "test_helper"

class RowTest < ActiveSupport::TestCase
  class GeometryTest < RowTest
    test "empty geometry is invalid" do
      row = Row.new(author: users(:reclus), layer: layers(:hiking_zones))
      row.validate

      assert_equal [{error: :required}], row.errors.details[:geometry]
    end

    test "invalid geometry is invalid" do
      row = Row.new(author: users(:reclus), layer: layers(:hiking_zones), geometry: "POLYGON ((0 0, 0 1, 1 0, 1 1, 0 0))")
      row.validate

      assert_equal [{error: :invalid, reason: "Self-intersection"}], row.errors.details[:geometry]
    end

    test "Only first geometry of geometry collection is taken" do
      row = Row.new(author: users(:reclus), layer: layers(:restaurants), geometry: "MULTIPOINT (10 40, 40 30, 20 20, 30 10)")
      row.validate

      assert_equal [{error: :multiple_items}], row.warnings.details[:geometry]
      assert_equal RGEO_FACTORY.point(10, 40), RGEO_FACTORY.parse_wkt(row.geometry.as_text) # Make sure to use the same factory for comparison
    end

    test "compute bounds" do # rubocop:disable Minitest/MultipleAssertions
      layer = layers(:restaurants)
      bounds = layer.rows.bounding_box

      assert_in_epsilon 2.37516, bounds[0]
      assert_in_epsilon 48.88661, bounds[1]
      assert_in_epsilon 2.37516, bounds[2]
      assert_in_epsilon 48.88661, bounds[3]

      layer.rows.create(point: "POINT(2 40)", author: users("reclus"))
      layer.rows.create(point: "POINT(3 50)", author: users("reclus"))
      extended_bounds = layer.rows.bounding_box

      assert_in_epsilon 2, extended_bounds[0]
      assert_in_epsilon 40, extended_bounds[1]
      assert_in_epsilon 3, extended_bounds[2]
      assert_in_epsilon 50, extended_bounds[3]
    end
  end

  class FieldsValuesTest < RowTest
    # Read values from DB
    test "value is returned" do
      row = layers(:restaurants).rows.new(values: {fields(:restaurant_name).id => "Le Bastringue"})

      assert_equal "Le Bastringue", row.fields_values[fields(:restaurant_name)]
    end

    test "invalid field identifier is filtered" do
      row = layers(:restaurants).rows.new(values: {invalid_field_identifier: "whatever"})

      assert_nil row.fields_values[:invalid_field_identifier]
    end

    test "territory value is returned as Territory object" do
      antipode = rows("antipode")

      antipode_from_db = layers("restaurants").rows.includes(layers("restaurants").fields_association_names).find(antipode.id)

      assert_equal territories("paris"), antipode_from_db.fields_values[fields(:restaurant_ville)]
    end

    test "invalid territory identifier is ignored" do
      antipode = rows("antipode")
      antipode.fields_values = {fields(:restaurant_ville).id => "invalid identifier"}
      antipode.save!

      antipode_from_db = layers("restaurants").rows.includes(layers("restaurants").fields_association_names).find(antipode.id)

      assert_nil antipode_from_db.fields_values[fields(:restaurant_ville)]
    end

    # Set values from user input
    test "value is saved" do
      row = layers(:restaurants).rows.new
      row.fields_values = {fields(:restaurant_name).id => "Le Bastringue"}

      assert_equal "Le Bastringue", row.values[fields(:restaurant_name).id]
    end

    test "invalid field identifier is not saved" do
      row = layers(:restaurants).rows.new
      row.fields_values = {invalid_field_identifier: "whatever"}

      assert_nil row.values[:invalid_field_identifier]
    end

    test "valid territory id is saved" do
      row = layers(:restaurants).rows.new
      row.fields_values = {fields(:restaurant_ville).id => territories("paris").id}

      assert_equal territories("paris").id, row.values[fields(:restaurant_ville).id]
    end

    test "invalid territory id is ignored" do
      row = layers(:restaurants).rows.new
      row.fields_values = {fields(:restaurant_ville).id => "invalid_identifier"}

      assert_nil row.values[fields(:restaurant_ville).id]
    end

    test "partial values hash do not clear other valid values" do
      row = Row.new(layer: layers(:restaurants), values: {fields(:restaurant_name).id => "Le Bastringue", fields(:restaurant_rating).id => 5})
      row.fields_values = {fields(:restaurant_name).id => "Le Bistrot"}

      assert_equal "Le Bistrot", row.values[fields(:restaurant_name).id]
      assert_equal 5, row.values[fields(:restaurant_rating).id]
    end
  end
end
