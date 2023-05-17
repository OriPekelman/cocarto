require "test_helper"

class MapControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "access control works" do
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

  test "anonymous access to a shared map succeeds" do
    get map_shared_url(map_tokens(:restaurants_viewers).token)

    assert_response :success
  end

  test "anonymous access to a shared map increases counter" do
    assert_changes -> { map_tokens(:restaurants_viewers).reload.access_count } do
      get map_shared_url(map_tokens(:restaurants_viewers).token)
    end
  end

  test "anonymous access to a a map keeps the token in a cookie" do
    get map_shared_url(map_tokens(:restaurants_viewers).token)

    assert_equal [map_tokens(:restaurants_viewers).token], session["cocarto.anonymous.map_tokens"]
  end

  test "anonymous access to a one map with several tokens keeps the best token" do
    get map_shared_url(map_tokens(:restaurants_viewers).token)
    get map_shared_url(map_tokens(:restaurants_contributors).token)
    get map_shared_url(map_tokens(:restaurants_viewers).token)

    assert_equal [map_tokens(:restaurants_contributors).token], session["cocarto.anonymous.map_tokens"]
  end

  test "anonymous access to several shared maps keeps working for the first map" do
    get map_shared_url(map_tokens(:restaurants_contributors).token)
    get map_shared_url(map_tokens(:boat_viewers).token)

    assert_response :success

    get map_shared_url(map_tokens(:restaurants_contributors).token)

    assert_response :success
  end

  test "anonymous access to several shared maps keeps several tokens" do
    get map_shared_url(map_tokens(:restaurants_contributors).token)
    get map_shared_url(map_tokens(:boat_viewers).token)

    assert_equal map_tokens(:restaurants_contributors, :boat_viewers).pluck(:token), session["cocarto.anonymous.map_tokens"]
  end

  test "anonymous access to shared maps grants access to the /maps page" do
    get map_shared_url(map_tokens(:restaurants_viewers).token)
    get maps_url

    assert_response :success
  end

  test "access to a shared map as an existing user succeeds and creates a new role" do
    sign_in users(:cassini)

    assert_changes -> { users(:cassini).maps.count } do
      get map_shared_url(map_tokens(:restaurants_contributors).token)

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
