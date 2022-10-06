require "test_helper"

class LayerControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "acces control" do
    restaurants = layers(:restaurants)
    get layer_url(id: restaurants.id)
    assert_redirected_to root_path(locale: :en)

    sign_in users(:cassini)
    get layer_url(id: restaurants.id)
    assert_redirected_to root_path(locale: :en)

    sign_in users(:reclus)
    get layer_url(id: restaurants.id)
    assert_response :success
  end

  test "geojson endpoint" do
    sign_in users(:reclus)
    restaurants = layers(:restaurants)
    get geojson_layer_url(id: restaurants.id)
    assert_equal "application/geo+json", @response.media_type
    geojson = JSON.parse(@response.body)
    assert_equal "Point", geojson.dig("features", 0, "geometry", "type")
  end

  test "geojson endpoint with token" do
    restaurants = layers(:restaurants)
    get geojson_layer_url(id: restaurants.id), headers: {apikey: "BAD"}
    assert_response 401

    get geojson_layer_url(id: restaurants.id), headers: {apikey: "let me in"}
    geojson = JSON.parse(@response.body)
    assert_equal "Point", geojson.dig("features", 0, "geometry", "type")
  end
end
