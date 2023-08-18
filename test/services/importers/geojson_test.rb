require "test_helper"

class Importers::GeoJSONTest < ActiveSupport::TestCase
  class Import < self
    test "import geojson" do
      layers(:restaurants).rows.destroy_all

      mapping = layers(:restaurants).import_mappings.new(source_layer_name: "restaurants")
      config = maps(:restaurants).import_configurations.new(source_text_encoding: nil)
      geojson = file_fixture("restaurants.geojson").open

      assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 2 do
        Importers::GeoJSON.new(config, geojson, users(:reclus)).import_rows(mapping.reports.new)
      end
    end
  end
end
