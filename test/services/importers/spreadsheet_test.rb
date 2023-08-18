require "test_helper"

class Importers::SpreadsheetTest < ActiveSupport::TestCase
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
