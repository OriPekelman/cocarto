require "test_helper"
require "webrick"
require "fixtures/mock_wks_server"

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

  class WFS < ImporterTest
    include MockWfsServer

    test "wfs import" do
      assert_changes -> { layers(:hiking_paths).rows.count }, from: 1, to: 5 do
        result = ImportExport.import(layers(:hiking_paths), :wfs, "http://localhost:9090", input_layer_name: "TEST_FEATURE_NAME", author: users(:reclus))

        assert_predicate result, :success?
      end

      assert_predicate layers(:hiking_paths).rows.find_by("values ->> '#{fields("hiking_paths_name").id}' = 'Tracé numéro un'"), :present?
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

    test "automatic column" do
      layers(:restaurants).rows.destroy_all

      csv = <<~CSV
        Name,lat,long
        AAA,10,10
        BBB,20,20
      CSV

      ImportExport.import(layers(:restaurants), :csv, csv, author: users(:reclus))

      assert_equal 2, layers(:restaurants).rows.count
    end
  end
end
