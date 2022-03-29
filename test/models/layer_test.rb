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
