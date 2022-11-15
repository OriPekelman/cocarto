require "test_helper"

class MapControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "acces control" do
    restaurants = maps(:restaurants)
    get map_url(id: restaurants.id)
    assert_redirected_to root_path(locale: :en)

    sign_in users(:cassini)
    get map_url(id: restaurants.id)
    assert_redirected_to root_path(locale: :en)

    sign_in users(:reclus)
    get map_url(id: restaurants.id)
    assert_response :success
  end
end
