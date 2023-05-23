require "test_helper"

class MapControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "access control" do
    restaurants = maps(:restaurants)
    get map_url(id: restaurants.id)

    assert_redirected_to new_user_session_path

    sign_in users(:cassini)
    get map_url(id: restaurants.id)

    assert_redirected_to root_path(locale: :en)

    sign_in users(:reclus)
    get map_url(id: restaurants.id)

    assert_response :success
  end

  test "anonymous access to a shared map creates a new user" do
    assert_changes -> { User.count } do
      get map_shared_url(access_groups(:restaurants_contributors).token)

      assert_redirected_to map_url(maps(:restaurants))
    end
  end

  test "access to a shared map as an existing user" do
    sign_in users(:cassini)

    assert_changes -> { users(:cassini).maps.count } do
      get map_shared_url(access_groups(:restaurants_contributors).token)

      assert_redirected_to map_url(maps(:restaurants))
    end
  end

  test "get a style" do
    sign_in users(:reclus)
    get map_url(id: maps(:restaurants).id, format: :style)
    style = JSON.parse(response.body) # rubocop:disable Rails/ResponseParsedBody
    layer_ids = style["layers"].pluck("id")

    assert_includes layer_ids, dom_id(layers(:restaurants))
  end
end
