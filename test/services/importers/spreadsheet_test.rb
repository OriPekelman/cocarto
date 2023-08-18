require "test_helper"

class Importers::SpreadsheetTest < ActiveSupport::TestCase
  class Analyse < self
    test "layer_names" do
      config = maps(:restaurants).import_configurations.new
      xlsx = file_fixture("restaurants.xlsx").open

      layer_names = Importers::Spreadsheet.new(config, xlsx, nil)._source_layers

      assert_equal ["restaurants", "feuille vide"], layer_names
    end

    test "layer_columns" do
      config = maps(:restaurants).import_configurations.new
      xlsx = file_fixture("restaurants.xlsx").open

      source_columns = Importers::Spreadsheet.new(config, xlsx, nil)._source_columns("restaurants")

      assert_equal({"Name" => String, "Rating" => Integer, "Table Size" => Integer, "Ville" => Integer, "Date" => NilClass, "Decision" => NilClass, "geojson" => String}, source_columns)
    end

    test "geometry_attributes" do
      config = maps(:restaurants).import_configurations.new
      xlsx = file_fixture("restaurants.xlsx").open

      analysis = Importers::Spreadsheet.new(config, xlsx, nil)._source_geometry_analysis("restaurants")

      assert_equal ["geojson"], analysis.columns
      assert_equal :geojson, analysis.format
      assert_equal "Point", analysis.type
    end
  end

  class Import < self
    test "import excel (xslx) file" do
      layers(:restaurants).rows.destroy_all

      mapping = layers(:restaurants).import_mappings.new(source_layer_name: "restaurants")
      config = maps(:restaurants).import_configurations.new
      xlsx = file_fixture("restaurants.xlsx").open

      assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 2 do
        Importers::Spreadsheet.new(config, xlsx, users(:reclus)).import_rows(mapping.reports.new)
      end
    end

    test "import excel (xls) file" do
      layers(:restaurants).rows.destroy_all

      mapping = layers(:restaurants).import_mappings.new(source_layer_name: "restaurants")
      config = maps(:restaurants).import_configurations.new
      xls = file_fixture("restaurants.xls").open

      assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 2 do
        Importers::Spreadsheet.new(config, xls, users(:reclus)).import_rows(mapping.reports.new)
      end
    end

    test "import opendocument (ods) file" do
      layers(:restaurants).rows.destroy_all

      mapping = layers(:restaurants).import_mappings.new(source_layer_name: "restaurants")
      config = maps(:restaurants).import_configurations.new
      ods = file_fixture("restaurants.ods").open

      assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 2 do
        Importers::Spreadsheet.new(config, ods, users(:reclus)).import_rows(mapping.reports.new)
      end
    end
  end
end
