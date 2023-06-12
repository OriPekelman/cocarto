require "test_helper"

class LayerControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  class ExportTest < LayerControllerTest
    test "API access does not create a new User" do
      assert_no_changes -> { User.count } do
        get layer_url(layers(:restaurants), format: :geojson, authkey: map_tokens(:restaurants_viewers).token)
      end
    end

    test "export fails when not connected" do
      get layer_url(layers(:restaurants), format: :geojson)

      assert_response :unauthorized
    end

    test "export works when connected" do
      sign_in users(:reclus)
      get layer_url(layers(:restaurants), format: :geojson)

      assert_response :success
    end

    test "export works when using token in param or in header" do
      get layer_url(layers(:restaurants), format: :geojson, authkey: map_tokens(:restaurants_viewers).token)

      assert_response :success

      get layer_url(layers(:restaurants), format: :geojson), headers: {"x-auth-key": map_tokens(:restaurants_viewers).token}

      assert_response :success
    end

    test "export fails when using wrong token" do
      get layer_url(layers(:restaurants), format: :geojson, headers: {"x-auth-key": "BAD"})

      assert_response :unauthorized
    end

    test "geojson is correctly formed" do
      get layer_url(layers(:restaurants), format: :geojson, authkey: map_tokens(:restaurants_viewers).token)

      geojson = JSON.parse(@response.body)

      assert_equal "application/geo+json", @response.media_type
      assert_equal "Point", geojson.dig("features", 0, "geometry", "type")
    end

    test "csv is correctly formed" do
      get layer_url(layers(:restaurants), format: :csv, authkey: map_tokens(:restaurants_viewers).token)

      csv = CSV.parse(@response.body)

      assert_equal "text/csv", @response.media_type
      assert_equal "geojson", csv.dig(0, 0)
    end

    test "mvt of a layer with some data in it" do
      sign_in users(:reclus)
      get url_for(controller: :layers, action: :mvt, id: layers(:restaurants).id, x: 518, y: 352, z: 10)

      assert @response.body.size > 0
    end

    test "mvt of a layer with no data because there is nothing on that tile" do
      sign_in users(:reclus)
      get url_for(controller: :layers, action: :mvt, id: layers(:restaurants).id, x: 100, y: 100, z: 10)

      assert_equal 0, @response.body.size
    end

    test "computed columns are exported" do
      sign_in users(:cassini)
      get layer_url(layers(:hiking_paths), format: :geojson)
      geojson = JSON.parse(@response.body)

      assert_in_delta(19720.582, geojson.dig("features", 0, "properties", "calculated_length"))
    end
  end
end
