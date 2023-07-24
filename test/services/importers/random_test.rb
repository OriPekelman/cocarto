require "test_helper"

class Importers::RandomTest < ActiveSupport::TestCase
  test "generate random rows" do
    assert_changes -> { layers(:restaurants).rows.count }, from: 1, to: 101 do
      mapping = layers(:restaurants).import_mappings.new(source_layer_name: "restaurants")
      config = maps(:restaurants).import_configurations.new
      Importers::Random.new(config, file_fixture("random_restaurants.json"), users(:reclus))
        .import_rows(mapping.reports.new)
    end
  end
end
