# == Schema Information
#
# Table name: layers
#
#  id            :uuid             not null, primary key
#  geometry_type :enum             geometry, 0
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :uuid             not null
#
# Indexes
#
#  index_layers_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class LayerTest < ActiveSupport::TestCase
  test "create a new layer" do
    assert_equal 1, users(:reclus).layers.count
    assert_equal 1, users(:cassini).layers.count

    a = Layer.new geometry_type: :point, user: users(:reclus)
    a.save!
    assert a

    assert_equal 2, users(:reclus).layers.count
    assert_equal 1, users(:cassini).layers.count
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
