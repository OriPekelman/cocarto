require "test_helper"

class ImporterTest < ActiveSupport::TestCase
  class Random < ImporterTest
    test "generate random rows" do
      assert_changes -> { layers(:restaurants).rows.count }, from: 1, to: 101 do
        ImportExport.import(layers(:restaurants), :random, nil, row_count: 100, author: users(:reclus), lat_range: -49.30..49.20, long_range: 69.10..69.20)
      end
    end
  end

  class CSV < ImporterTest
    test "import csv" do
      layers(:restaurants).rows.destroy_all

      csv = file_fixture("restaurants.csv").open
      assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 2 do
        ImportExport.import(layers(:restaurants), :csv, csv, author: users(:reclus))
      end
    end

    test "csv column separator detection" do
      layers(:restaurants).rows.destroy_all

      csv = <<~CSV
        Nom;Convives;geojson
        L’Antipode;70;"{""type"":""Point"",""coordinates"":[2.37516,48.88661]}"
      CSV

      assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 1 do
        ImportExport.import(layers(:restaurants), :csv, csv, author: users(:reclus))
      end
    end
  end

  class Mapping < ImporterTest
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
  end

  class Reimport < ImporterTest
    test "reimport should only update the values" do
      layers(:restaurants).rows.destroy_all

      csv = file_fixture("restaurants.csv").open

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

  class GeometryFormats < ImporterTest
    test "from wkt column" do
      layers(:restaurants).rows.destroy_all

      csv = <<~CSV
        Name,geometry
        AAA,POINT (10 20)
        BBB,POINT (30 40)
      CSV

      ImportExport.import(layers(:restaurants), :csv, csv, author: users(:reclus), geometry_keys: "geometry", geometry_format: :wkt)

      assert_equal 2, layers(:restaurants).rows.count
    end

    test "from lat long columns" do
      layers(:restaurants).rows.destroy_all

      csv = <<~CSV
        Name,lat,long
        AAA,10,10
        BBB,20,20
      CSV

      ImportExport.import(layers(:restaurants), :csv, csv, author: users(:reclus), geometry_keys: %w[long lat], geometry_format: :xy)

      assert_equal 2, layers(:restaurants).rows.count
    end
  end
end
