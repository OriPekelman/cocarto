require "test_helper"

class MapControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "acces control" do
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

  test "get a style" do
    sign_in users(:reclus)
    get map_url(id: maps(:restaurants).id, format: :style)
    style = JSON.parse(response.body) # rubocop:disable Rails/ResponseParsedBody
    layer_ids = style["layers"].pluck("id")

    assert_includes layer_ids, dom_id(layers(:restaurants))
  end
end
