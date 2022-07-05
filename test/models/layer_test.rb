# == Schema Information
#
# Table name: layers
#
#  id            :uuid             not null, primary key
#  geometry_type :enum             geometry, 0
#  name          :string
#  style         :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  map_id        :uuid             not null
#
# Indexes
#
#  index_layers_on_map_id  (map_id)
#
# Foreign Keys
#
#  fk_rails_...  (map_id => maps.id)
#
require "test_helper"

class LayerTest < ActiveSupport::TestCase
  test "create a new layer" do
    assert_changes -> { maps(:one).layers.count }, from: 1, to: 2 do
      Layer.create! geometry_type: :point, map: maps(:one)
    end

    assert_equal 1, maps(:two).layers.count
  end

  test "a layer needs a geometry type" do
    a = Layer.new
    assert_raises(ActiveRecord::RecordInvalid) { a.save! }
  end

  test "a layer needs a valid geometry type" do
    a = Layer.new geometry_type: :hypercube
    assert_raises(ActiveRecord::RecordInvalid) { a.save! }
  end
end
