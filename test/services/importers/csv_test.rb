require "test_helper"

class Importers::CSVTest < ActiveSupport::TestCase
  test "import csv" do
    layers(:restaurants).rows.destroy_all

    mapping = layers(:restaurants).import_mappings.new(source_layer_name: "restaurants")
    config = maps(:restaurants).import_configurations.new(source_text_encoding: nil)
    csv = file_fixture("restaurants.csv").open

    assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 2 do
      Importers::CSV.new(config, csv, users(:reclus)).import_rows(mapping.reports.new)
    end
  end

  test "csv column separator detection" do
    layers(:restaurants).rows.destroy_all

    mapping = layers(:restaurants).import_mappings.new(source_layer_name: "restaurants")
    config = maps(:restaurants).import_configurations.new
    csv = <<~CSV
      Nom;Convives;geojson
      L’Antipode;70;"{""type"":""Point"",""coordinates"":[2.37516,48.88661]}"
    CSV

    assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 1 do
      Importers::CSV.new(config, csv, users(:reclus)).import_rows(mapping.reports.new)
    end
  end
end
