require "test_helper"

class Importers::RandomTest < ActiveSupport::TestCase
  test "generate random rows" do
    layers(:restaurants).rows.destroy_all

    random = file_fixture("random_restaurants.json").open
    config, mapping = preconfigured_import(:restaurants, :random, random)

    assert_changes -> { layers(:restaurants).rows.count }, from: 0, to: 100 do
      Importers::Random.new(config, random, users(:reclus)).import_rows(mapping.reports.new)
    end
  end
end
