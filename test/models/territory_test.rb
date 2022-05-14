require "test_helper"
require_relative "../../lib/geojson_importer"

class TerritoryTest < ActiveSupport::TestCase
  test "geography works" do
    paris = territories(:paris)
    idf = territories(:idf)
    assert_equal "Paris", paris.name
    t = Territory.arel_table
    # An object is included in itself, so we filter out idf
    # idf contains paris
    assert_equal paris, Territory.where.not(id: idf.id).where(t[:geometry].st_contains(paris.geometry)).first
    # Nothing contains idf
    assert Territory.where.not(id: idf.id).where(t[:geometry].st_contains(idf.geometry)).empty?
  end

  test "import from geojson" do
    GeojsonImporter.import("lib/assets/data_fixtures/regions.geojson", "Régions", "2022", true)
    regions = TerritoryCategory.find_by(name: "Régions")
    assert_equal 18, regions.territories.length

    # Test that it calls the with_geojson scope
    assert !regions.territories.first.geojson.nil?
  end

  test "we have geojson and geojson bounding" do
    GeojsonImporter.import("lib/assets/data_fixtures/regions.geojson", "Régions", "2022", true)
    guadeloupe = Territory.with_geojson.find_by(name: "Guadeloupe")
    assert_in_epsilon guadeloupe.lng_min, -61.801
    assert_in_epsilon guadeloupe.lat_min, 15.947
    assert_in_epsilon guadeloupe.lng_max, -61.29
    assert_in_epsilon guadeloupe.lat_max, 16.465
  end
end
