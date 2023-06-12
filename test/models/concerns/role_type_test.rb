require "test_helper"

class RoleTypeTest < ActiveSupport::TestCase
  test "user_role access" do
    assert user_roles(:boat_reclus).is_at_least(:owner)
    assert_not user_roles(:boat_cassini).is_at_least(:editor)

    assert user_roles(:boat_reclus).is_stronger_than(user_roles(:boat_cassini))
  end

  test "map_token access" do
    assert map_tokens(:restaurants_contributors).is_at_least(:contributor)
    assert map_tokens(:restaurants_viewers).is_at_least(:viewer)

    assert map_tokens(:restaurants_contributors).is_stronger_than(map_tokens(:restaurants_viewers))
  end

  test "mixed access modes" do
    assert user_roles(:restaurants_reclus).is_stronger_than(map_tokens(:restaurants_contributors))
  end
end
