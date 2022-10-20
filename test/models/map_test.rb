# == Schema Information
#
# Table name: maps
#
#  id         :uuid             not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class MapTest < ActiveSupport::TestCase
  class Queries < MapTest
    test "#layer_with_last_updated_row, #last_updated_row, #last_updated_row_author" do
      row = maps(:restaurants).layers.last.rows.create!(author: users(:cassini), point: "POINT(0.0001 0.0001)")
      assert_equal layers(:restaurants), maps(:restaurants).layer_with_last_updated_row
      assert_equal row, maps(:restaurants).last_updated_row
      assert_equal users(:cassini), maps(:restaurants).last_updated_row_author
    end
  end
end
