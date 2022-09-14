require "application_system_test_case"

class LayersTest < ApplicationSystemTestCase
  test "visit a layer page" do
    sign_in_as(users("reclus"), "refleurir")

    visit layer_path(id: layers("restaurants"))
    assert_field "layer[name]", with: "Restaurants"
  end
end
