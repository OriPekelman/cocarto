require "test_helper"

class ExporterTest < ActiveSupport::TestCase
  class Geojson < ExporterTest
    test "points layer" do
      geojson = <<~GEOJSON.squish
        {"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[2.37516,48.88661]},"properties":{"Name":"L’Antipode","Rating":"9","Table Size":"70","Ville":"75056","Date":null,"Decision":null}}]}
      GEOJSON
      assert_equal geojson, ImportExport.export(layers(:restaurants), :geojson)
    end

    test "line layer" do
      geojson = <<~GEOJSON.squish
        {"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"LineString","coordinates":[[2.749597345,48.803795844],[2.834344424,48.752477597],[2.7702115,48.728309678],[2.829763501,48.693547935]]},"properties":{"Document":"touladi.png","calculated_length":"19720.5819932504"}}]}
      GEOJSON
      assert_equal geojson, ImportExport.export(layers(:hiking_paths), :geojson)
    end

    test "polygon layer" do
      geojson = <<~GEOJSON.squish
        {"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[2.747403413,48.84348962],[2.887763814,48.796096072],[2.751002398,48.736791112],[2.639433875,48.800837444],[2.747403413,48.84348962]]]},"properties":{"calculated_area":"108167884.855621"}}]}
      GEOJSON
      assert_equal geojson, ImportExport.export(layers(:hiking_zones), :geojson)
    end

    test "territory layer" do
      geojson = <<~GEOJSON.squish
        {"type":"FeatureCollection","features":[{"type":"Feature","geometry":null,"properties":{"territory":"11","calculated_area":"12003436297.6058"}}]}
      GEOJSON
      assert_equal geojson, ImportExport.export(layers(:hiking_regions), :geojson)
    end

    test "files field" do
      geojson = <<~GEOJSON.squish
        {"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"LineString","coordinates":[[2.749597345,48.803795844],[2.834344424,48.752477597],[2.7702115,48.728309678],[2.829763501,48.693547935]]},"properties":{"Document":"touladi.png","calculated_length":"19720.5819932504"}}]}
      GEOJSON
      assert_equal geojson, ImportExport.export(layers(:hiking_paths), :geojson)
    end

    test "territory field" do
      geojson = <<~GEOJSON.squish
        {"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[2.37516,48.88661]},"properties":{"Name":"L’Antipode","Rating":"9","Table Size":"70","Ville":"75056","Date":null,"Decision":null}}]}
      GEOJSON
      assert_equal geojson, ImportExport.export(layers(:restaurants), :geojson)
    end
  end

  class Csv < ExporterTest
    test "points layer" do
      csv = <<~CSV
        geojson,Name,Rating,Table Size,Ville,Date,Decision
        "{""type"":""Point"",""coordinates"":[2.37516,48.88661]}",L’Antipode,9,70,75056,,
      CSV
      assert_equal csv, ImportExport.export(layers(:restaurants), :csv)
    end

    test "line layer" do
      csv = <<~CSV
        geojson,Document,calculated_length
        "{""type"":""LineString"",""coordinates"":[[2.749597345,48.803795844],[2.834344424,48.752477597],[2.7702115,48.728309678],[2.829763501,48.693547935]]}",touladi.png,19720.5819932504
      CSV
      assert_equal csv, ImportExport.export(layers(:hiking_paths), :csv)
    end

    test "polygon layer" do
      csv = <<~CSV
        geojson,calculated_area
        "{""type"":""Polygon"",""coordinates"":[[[2.747403413,48.84348962],[2.887763814,48.796096072],[2.751002398,48.736791112],[2.639433875,48.800837444],[2.747403413,48.84348962]]]}",108167884.855621
      CSV
      assert_equal csv, ImportExport.export(layers(:hiking_zones), :csv)
    end

    test "territory layer" do
      csv = <<~CSV
        territory,calculated_area
        11,12003436297.6058
      CSV
      assert_equal csv, ImportExport.export(layers(:hiking_regions), :csv)
    end

    test "files field" do
      csv = <<~CSV
        geojson,Document,calculated_length
        "{""type"":""LineString"",""coordinates"":[[2.749597345,48.803795844],[2.834344424,48.752477597],[2.7702115,48.728309678],[2.829763501,48.693547935]]}",touladi.png,19720.5819932504
      CSV
      assert_equal csv, ImportExport.export(layers(:hiking_paths), :csv)
    end

    test "territory field" do
      csv = <<~CSV
        geojson,Name,Rating,Table Size,Ville,Date,Decision
        "{""type"":""Point"",""coordinates"":[2.37516,48.88661]}",L’Antipode,9,70,75056,,
      CSV
      assert_equal csv, ImportExport.export(layers(:restaurants), :csv)
    end
  end
end
