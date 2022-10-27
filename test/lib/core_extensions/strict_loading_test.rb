require "test_helper"

class StrictLoadingTest < ActiveSupport::TestCase
  test "loading a :has_many relations of each object of a collection is not allowed" do
    map = Map.all.to_a.first

    assert_equal :all, map.strict_loading_mode

    assert_raises(ActiveRecord::StrictLoadingViolationError) do
      map.layers.to_a
    end
  end

  test "loading a :has_many relation of a single object is allowed" do
    map = Map.find_by(name: "Restaurants")

    assert_equal :n_plus_one_only, map.strict_loading_mode
    assert map.layers.all? { _1.strict_loading_mode == :all }

    # Loading a :has_many relation of these objects is *not* allowed
    assert_raises(ActiveRecord::StrictLoadingViolationError) do
      map.layers.first.rows.to_a
    end
  end

  test "overriding the loading mode is allowed" do
    map = Map.all.to_a.first
    map.strict_loading!(true, mode: :n_plus_one_only)

    assert_nothing_raised do
      map.layers.to_a
    end
  end
end
