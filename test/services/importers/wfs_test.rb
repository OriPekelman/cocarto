require "test_helper"

class Importers::WFSTest < ActiveSupport::TestCase
  setup { start_fixtures_server }

  class Import < self
    test "wfs import" do
      assert_changes -> { layers(:hiking_paths).rows.count }, from: 1, to: 5 do
        config = {}
        mapping = import_mappings(:hiking_paths_wfs)
        mapping.source_layer_name = "TEST_FEATURE_NAME"
        report = mapping.reports.new
        Importers::WFS.new(config, "#{fixtures_server_url}/wfs", users(:reclus))
          .import_rows(report)
      end

      assert_predicate layers(:hiking_paths).rows.find_by("values ->> '#{fields("hiking_paths_name").id}' = 'Tracé numéro un'"), :present?
    end
  end
end
