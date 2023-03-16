require "test_helper"

class ExporterTest < ActiveSupport::TestCase
  test "csv of points" do
    export = ImportExport::Exporter.new(layers(:restaurants))

    csv = <<~CSV
      Name,Rating,Table Size,Ville,Date,Decision,geojson
      L’Antipode,9,70,75056,,,"{""type"":""Point"",""coordinates"":[2.37516,48.88661]}"
    CSV
    assert_equal csv, export.csv
  end
end
