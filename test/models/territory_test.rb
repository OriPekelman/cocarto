require "test_helper"
require_relative "../../lib/geojson_importer"

class TerritoryTest < ActiveSupport::TestCase
  def setup
    GeojsonImporter.import("lib/assets/data_fixtures/regions.geojson", "Régions", "2022", true)
  end

  test "import from geojson" do
    regions = TerritoryCategory.find_by(name: "Régions")
    assert_equal 18, regions.territories.length

    # Test that it calls the with_geojson scope
    assert !regions.territories.first.geojson.nil?
  end

  test "we have geojson and geojson bounding" do
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
