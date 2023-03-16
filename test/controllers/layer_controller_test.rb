require "test_helper"

class LayerControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  class ExportTest < LayerControllerTest
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
      get layer_url(layers(:restaurants), format: :geojson, authkey: "let me in")

      assert_response :success

      get layer_url(layers(:restaurants), format: :geojson), headers: {"x-auth-key": "let me in"}

      assert_response :success
    end

    test "export fails when using wrong token" do
      get layer_url(layers(:restaurants), format: :geojson, headers: {"x-auth-key": "BAD"})

      assert_response :unauthorized
    end

    test "geojson is correctly formed" do
      get layer_url(layers(:restaurants), format: :geojson, authkey: "let me in")

      geojson = JSON.parse(@response.body)

      assert_equal "application/geo+json", @response.media_type
      assert_equal "Point", geojson.dig("features", 0, "geometry", "type")
    end

    test "csv is correctly formed" do
      get layer_url(layers(:restaurants), format: :csv, authkey: "let me in")

      csv = CSV.parse(@response.body)

      assert_equal "text/csv", @response.media_type
      assert_equal "geojson", csv.dig(0, 0)
    end
  end
end
