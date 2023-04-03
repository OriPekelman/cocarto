require "test_helper"

class ImporterTest < ActiveSupport::TestCase
  test "create_random_rows" do
    import = ImportExport::Importer.new(layers(:restaurants))
    assert_changes -> { layers(:restaurants).rows.count }, from: 1, to: 101 do
      import.create_random_rows(100, users(:reclus), -49.30..49.20, 69.10..69.20)
    end
  end

  test "import csv" do
    layers(:restaurants).rows.destroy_all
    import = ImportExport::Importer.new(layers(:restaurants))

    csv = <<~CSV
      Name,Rating,Table Size,Ville,Date,Decision,geojson
      L’Antipode,9,70,75056,,,"{""type"":""Point"",""coordinates"":[2.37516,48.88661]}"
    CSV

    assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 1 do
      import.csv(csv, users(:reclus))
    end
  end
end
