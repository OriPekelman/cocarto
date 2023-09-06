# == Schema Information
#
# Table name: layers
#
#  id            :uuid             not null, primary key
#  geometry_type :enum             geometry, 0
#  name          :string
#  sort_order    :integer
#  style         :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  map_id        :uuid             not null
#
# Indexes
#
#  index_layers_on_map_id_and_sort_order  (map_id,sort_order) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (map_id => maps.id)
#
require "test_helper"

class LayerTest < ActiveSupport::TestCase
  class Validation < LayerTest
    test "create a new layer" do
      assert_changes -> { maps(:restaurants).layers.count }, from: 2, to: 3 do
        Layer.create! geometry_type: :point, map: maps(:restaurants)
      end
    end

    test "a layer needs a geometry type" do
      a = Layer.new
      assert_raises(ActiveRecord::RecordInvalid) { a.save! }
    end

    test "a layer needs a valid geometry type" do
      a = Layer.new
      assert_raises(ArgumentError) { a.geometry_type = :hypercube }
    end
  end

  class DependentDestruction < LayerTest
    test "destroying a layer destroys its fields" do
      layer = layers(:restaurants)
      territory_field = fields(:restaurant_ville)

      assert_nothing_raised { layer.destroy! }
      assert_raises(ActiveRecord::RecordNotFound) { territory_field.reload }
    end
  end

  class Queries < LayerTest
    test "#last_updated_row" do
      row = layers(:restaurants).rows.create!(author: users(:cassini), point: "POINT(0.0001 0.0001)")
      layer = Layer.where(id: layers(:restaurants)).with_last_updated_row_id.includes(:last_updated_row).first

      assert_equal row, layer.last_updated_row
    end

    test "#with_last_updated_row_id" do
      # Scoping with_last_updated_row_id should not exclude layers without rows
      assert_includes maps(:restaurants).layers.with_last_updated_row_id, layers(:empty_restaurants_layer)
    end
  end
end
