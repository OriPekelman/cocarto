require "test_helper"

class Importers::WFSTest < ActiveSupport::TestCase
  setup { start_fixtures_server }

  class Analyse < self
    test "_source_layers" do
      config = maps(:restaurants).import_configurations.new

      layer_names = Importers::WFS.new(config, "#{fixtures_server_url}/wfs", nil)._source_layers

      assert_equal ["TEST_FEATURE_NAME"], layer_names
    end

    test "_source_columns" do
      config = maps(:restaurants).import_configurations.new

      layer_names = Importers::WFS.new(config, "#{fixtures_server_url}/wfs", nil)._source_columns("TEST_FEATURE_NAME")

      assert_equal({"gml_id" => "String (0.0) NOT NULL", "Name" => "String (50.0)"}, layer_names)
    end

    test "_source_geometry" do # rubocop:disable MiniTest/MultipleAssertions
      config = maps(:restaurants).import_configurations.new

      geometry_analysis = Importers::WFS.new(config, "#{fixtures_server_url}/wfs", nil)._source_geometry_analysis("TEST_FEATURE_NAME")

      assert_equal ["SHAPE"], geometry_analysis.columns
      assert_equal "Multi Curve", geometry_analysis.type
    end
  end

  class Import < self
    test "wfs import" do
      wfs_url = "#{fixtures_server_url}/wfs"
      config, mapping = preconfigured_import(:hiking_paths, :wfs, wfs_url)

      assert_changes -> { layers(:hiking_paths).rows.count }, from: 1, to: 5 do
        Importers::WFS.new(config, wfs_url, users(:reclus)).import_rows(mapping.reports.new)
      end

      assert_predicate layers(:hiking_paths).rows.find_by("values ->> '#{fields("hiking_paths_name").id}' = 'Tracé numéro un'"), :present?
    end
  end
end
