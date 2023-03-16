require "test_helper"

class ImporterTest < ActiveSupport::TestCase
  test "create_random_rows" do
    import = ImportExport::Importer.new(layers(:restaurants))
    assert_changes -> { layers(:restaurants).rows.count }, from: 1, to: 101 do
      import.create_random_rows(100, users(:reclus), -49.30..49.20, 69.10..69.20)
    end
  end
end
