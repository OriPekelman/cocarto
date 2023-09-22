require "test_helper"

class Importers::GeometryParsingTest < ActiveSupport::TestCase
  class Parsing < self
    test "wkt column" do
      geom = Importers::GeometryParsing
        .extract_geometry({"geometry" => "POINT (10 20)"},
          %w[geometry],
          :wkt)

      assert_equal RGEO_FACTORY.point(10, 20), geom
    end

    test "lat long columns" do
      geom = Importers::GeometryParsing
        .extract_geometry({"long" => "10", "lat" => "20"},
          %w[long lat],
          :xy)

      assert_equal RGEO_FACTORY.point(10, 20), geom
    end
  end

  class Analyse < self
    test "auto analyse lat/long" do # rubocop: disable Minitest/MultipleAssertions
      analysis = Importers::GeometryParsing.analyse_geometry({"long" => "10", "lat" => "20"})

      assert_equal RGEO_FACTORY.point(10, 20), analysis.geometry
      assert_equal %w[long lat], analysis.columns
      assert_equal :xy, analysis.format
      assert_equal "Point", analysis.type
    end

    test "auto analyse geojson" do # rubocop: disable Minitest/MultipleAssertions
      analysis = Importers::GeometryParsing.analyse_geometry({"geom" => '{"type":"LineString","coordinates":[[10,20], [15, 25]]}'})

      assert_equal RGEO_FACTORY.line_string([RGEO_FACTORY.point(10, 20), RGEO_FACTORY.point(15, 25)]), analysis.geometry
      assert_equal %w[geom], analysis.columns
      assert_equal :geojson, analysis.format
      assert_equal "LineString", analysis.type
    end

    test "analyse with specified columns" do # rubocop: disable Minitest/MultipleAssertions
      analysis = Importers::GeometryParsing.analyse_geometry({"coord1" => "10", "coord2" => "20", "geom" => "POINT(1 1)"},
        columns: %w[coord1 coord2], format: :xy)

      assert_equal RGEO_FACTORY.point(10, 20), analysis.geometry
      assert_equal %w[coord1 coord2], analysis.columns
      assert_equal :xy, analysis.format
      assert_equal "Point", analysis.type
    end

    test "auto analyse with different casing" do
      analysis = Importers::GeometryParsing.analyse_geometry({"X" => "10", "Y" => "20"})

      assert_equal RGEO_FACTORY.point(10, 20), analysis.geometry
      assert_equal %w[X Y], analysis.columns
      assert_equal :xy, analysis.format
    end

    test "analyse with specified columns enforce casing" do # rubocop: disable Minitest/MultipleAssertions
      analysis = Importers::GeometryParsing.analyse_geometry({"coord1" => "10", "coord2" => "20", "COORD1" => "15"},
        columns: %w[coord1 coord2], format: :xy)

      assert_equal RGEO_FACTORY.point(10, 20), analysis.geometry
      assert_equal %w[coord1 coord2], analysis.columns
    end
  end
end
