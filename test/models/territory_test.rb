require "test_helper"

class TerritoryTest < ActiveSupport::TestCase
  test "geography works" do
    paris = territories(:paris)
    assert_equal "Paris", paris.name
    idf = territories(:idf)
    assert idf.geography.contains?(paris.geography.centroid)
  end
end
