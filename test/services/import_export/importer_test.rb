require "test_helper"

class ImporterTest < ActiveSupport::TestCase
  test "generate random rows" do
    assert_changes -> { layers(:restaurants).rows.count }, from: 1, to: 101 do
      ImportExport.import(layers(:restaurants), :random, nil, row_count: 100, author: users(:reclus), lat_range: -49.30..49.20, long_range: 69.10..69.20)
    end
  end

  test "import csv" do
    layers(:restaurants).rows.destroy_all

    csv = <<~CSV
      Name,Rating,Table Size,Ville,Date,Decision,geojson
      L’Antipode,9,70,75056,,,"{""type"":""Point"",""coordinates"":[2.37516,48.88661]}"
    CSV

    assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 1 do
      ImportExport.import(layers(:restaurants), :csv, csv, author: users(:reclus))
    end
  end
end
