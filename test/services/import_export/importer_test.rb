require "test_helper"

class ImporterTest < ActiveSupport::TestCase
  test "generate random rows" do
    assert_changes -> { layers(:restaurants).rows.count }, from: 1, to: 101 do
      ImportExport.import(layers(:restaurants), :random, nil, row_count: 100, author: users(:reclus), lat_range: -49.30..49.20, long_range: 69.10..69.20)
    end
  end

  test "import csv" do
    layers(:restaurants).rows.destroy_all

    csv = file_fixture("restaurants.csv").read
    assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 2 do
      ImportExport.import(layers(:restaurants), :csv, csv, author: users(:reclus))
    end
  end

  test "import with mapping" do
    layers(:restaurants).rows.destroy_all

    mapping = {
      "Nom" => fields(:restaurant_name).id,
      "Convives" => fields(:restaurant_table_size).id
    }
    csv = <<~CSV
      Nom,Convives,geojson
      L’Antipode,70,"{""type"":""Point"",""coordinates"":[2.37516,48.88661]}"
    CSV
    ImportExport.import(layers(:restaurants), :csv, csv, author: users(:reclus), mapping: mapping)

    row = layers(:restaurants).rows.includes(*layers(:restaurants).fields_association_names).last

    assert_equal "L’Antipode", row.fields_values[fields(:restaurant_name)]
    assert_equal 70, row.fields_values[fields(:restaurant_table_size)]
  end

  test "reimport should only update the values" do
    layers(:restaurants).rows.destroy_all

    csv = file_fixture("restaurants.csv").read

    ImportExport.import(layers(:restaurants), :csv, csv, author: users(:reclus), key_field: fields(:restaurant_name).id)
    bastringue = layers(:restaurants).rows.last

    assert_equal 5, bastringue.fields_values[fields(:restaurant_rating)]

    new_csv = <<~CSV
      Name,Rating
      Le Bastringue,10
    CSV
    ImportExport.import(layers(:restaurants), :csv, new_csv, author: users(:reclus), key_field: fields(:restaurant_name).id)

    assert_equal 2, layers(:restaurants).rows.count
    assert_equal 10, bastringue.reload.fields_values[fields(:restaurant_rating)]
  end
end
