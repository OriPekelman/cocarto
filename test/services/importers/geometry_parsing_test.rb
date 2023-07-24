require "test_helper"

class Importers::GeometryParsingTest < ActiveSupport::TestCase
  test "wkt column" do
    geom = Importers::GeometryParsing
      .extract_geometry({"geometry" => "POINT (10 20)"},
        "geometry",
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

  test "guessing" do
    geom = Importers::GeometryParsing
      .guess_geometry({"long" => "10", "lat" => "20"})

    assert_equal RGEO_FACTORY.point(10, 20), geom

    geom = Importers::GeometryParsing
      .guess_geometry({"geom" => '{"type":"Point","coordinates":[10,20]}'})

    assert_equal RGEO_FACTORY.point(10, 20), geom
  end
end
