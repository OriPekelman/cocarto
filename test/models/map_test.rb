# == Schema Information
#
# Table name: maps
#
#  id                :uuid             not null, primary key
#  default_latitude  :float
#  default_longitude :float
#  default_zoom      :float
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
require "test_helper"

class MapTest < ActiveSupport::TestCase
  class Queries < MapTest
    test "#last_updated_row" do
      row = maps(:restaurants).layers.last.rows.create!(author: users(:cassini), point: "POINT(0.0001 0.0001)")
      map = Map.where(id: maps(:restaurants)).with_last_updated_row_id.includes(:last_updated_row).first
      assert_equal row, map.last_updated_row
    end
  end
end
