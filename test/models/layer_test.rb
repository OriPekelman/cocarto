# == Schema Information
#
# Table name: layers
#
#  id            :uuid             not null, primary key
#  geometry_type :enum             geometry, 0
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require "test_helper"

class LayerTest < ActiveSupport::TestCase
  test "create a new layer" do
    a = Layer.new geometry_type: :point
    a.save!
    assert a
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
