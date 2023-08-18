require "test_helper"

class Importers::GeoJSONTest < ActiveSupport::TestCase
  class Analyse < self
    test "layer_columns" do
      config = maps(:restaurants).import_configurations.new(source_text_encoding: nil)
      geojson = file_fixture("restaurants.geojson").open

      source_columns = Importers::GeoJSON.new(config, geojson, nil)._source_columns("0")

      assert_equal({"Name" => String, "Rating" => Float, "Table Size" => Integer, "Ville" => NilClass, "Date" => NilClass, "Decision" => NilClass}, source_columns)
    end
  end

  class Import < self
    test "import geojson" do
      layers(:restaurants).rows.destroy_all

      geojson = file_fixture("restaurants.geojson").open
      config, mapping = preconfigured_import(:restaurants, :geojson, geojson)

      assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 2 do
        Importers::GeoJSON.new(config, geojson, users(:reclus)).import_rows(mapping.reports.new)
      end
    end
  end
end
