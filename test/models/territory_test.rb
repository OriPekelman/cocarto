# == Schema Information
#
# Table name: territories
#
#  id                    :uuid             not null, primary key
#  code                  :string
#  geometry              :geometry         multipolygon, 4326
#  name                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  parent_id             :uuid
#  territory_category_id :uuid             not null
#
# Indexes
#
#  index_territories_on_code_and_territory_category_id  (code,territory_category_id) UNIQUE
#  index_territories_on_name                            (name) USING gin
#  index_territories_on_parent_id                       (parent_id)
#  index_territories_on_territory_category_id           (territory_category_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => territories.id)
#  fk_rails_...  (territory_category_id => territory_categories.id)
#
require "test_helper"
require_relative "../../lib/geojson_importer"

class TerritoryTest < ActiveSupport::TestCase
  def setup
    GeojsonImporter.import(file_fixture("regions.geojson").to_path, "Régions", "2022", true)
  end

  test "import from geojson" do
    regions = TerritoryCategory.includes(:territories).find_by(name: "Régions")
    assert_equal 18, regions.territories.length

    # Test that it calls the with_geojson scope
    assert_not_nil regions.territories.first.geojson
  end

  test "we have geojson and geojson bounding" do # rubocop:disable Minitest/MultipleAssertions
    guadeloupe = Territory.with_geojson.find_by(name: "Guadeloupe")
    assert_in_epsilon guadeloupe.lng_min, -61.801
    assert_in_epsilon guadeloupe.lat_min, 15.947
    assert_in_epsilon guadeloupe.lng_max, -61.29
    assert_in_epsilon guadeloupe.lat_max, 16.465
  end

  test "search for autocomplete" do
    results = Territory.name_autocomplete("Breta")
    assert_equal "Bretagne", results[0].name
  end
end
