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
    # assert_equal "idf", idf.name
  end

  test "import from geojson" do
    GeojsonImporter.import("lib/assets/data_fixtures/regions.geojson", "Régions", "2022", true)
    regions = TerritoryCategory.where(name: "Régions").first
    assert_equal 18, regions.territories.length
  end
end
