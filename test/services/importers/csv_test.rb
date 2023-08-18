require "test_helper"

class Importers::CSVTest < ActiveSupport::TestCase
  class Analyse < self
    test "source_configuration" do
      csv = file_fixture("restaurants.csv").open
      config = maps(:restaurants).import_configurations.new

      analysis = Importers::CSV.new(config, csv, nil)._source_configuration

      assert_equal ",", analysis[:source_csv_column_separator]
    end

    test "layer_columns" do
      csv = file_fixture("restaurants.csv").open
      config = maps(:restaurants).import_configurations.new

      source_columns = Importers::CSV.new(config, csv, nil)._source_columns(0)

      assert_equal({"Name" => String, "Rating" => String, "Table Size" => String, "Ville" => String, "Date" => NilClass, "Decision" => NilClass, "geojson" => String}, source_columns)
    end

    test "mapping_geometry_attributes" do # rubocop:disable MiniTest/MultipleAssertions
      csv = file_fixture("restaurants.csv").open
      config = maps(:restaurants).import_configurations.new

      geometry_analysis = Importers::CSV.new(config, csv, nil)._source_geometry_analysis(0)

      assert_equal ["geojson"], geometry_analysis.columns
      assert_equal :geojson, geometry_analysis.format
      assert_equal RGEO_FACTORY.point(2.37516, 48.88661), geometry_analysis.geometry
      assert_equal "Point", geometry_analysis.type
    end
  end

  class Import < self
    test "import csv" do
      layers(:restaurants).rows.destroy_all

      csv = file_fixture("restaurants.csv").open
      config, mapping = preconfigured_import(:restaurants, :csv, csv)

      assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 2 do
        Importers::CSV.new(config, csv, users(:reclus)).import_rows(mapping.reports.new)
      end
    end
  end

  class Automatic < self
    test "Automatic separator detection" do
      layers(:restaurants).rows.destroy_all

      csv = <<~CSV
        Nom;Convives;geojson
        L’Antipode;70;"{""type"":""Point"",""coordinates"":[2.37516,48.88661]}"
      CSV
      config, mapping = preconfigured_import(:restaurants, :csv, csv)

      assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 1 do
        Importers::CSV.new(config, csv, users(:reclus)).import_rows(mapping.reports.new)
      end
    end
  end
end
