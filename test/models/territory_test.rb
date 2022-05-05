require "test_helper"

class TerritoryTest < ActiveSupport::TestCase
  test "geography works" do
    paris = territories(:paris)
    idf = territories(:idf)
    assert_equal "Paris", paris.name
    t = Territory.arel_table
    # An object is included in itself, so we filter out idf
    # idf contains paris
    assert_equal paris, Territory.where.not(id: idf.id).where(t[:geometry].st_contains(paris.geometry)).first
    # Nothing contains idf
    assert Territory.where.not(id: idf.id).where(t[:geometry].st_contains(idf.geometry)).empty?
    # assert_equal "idf", idf.name
  end
end
