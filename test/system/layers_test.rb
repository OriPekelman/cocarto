require "application_system_test_case"

class LayersTest < ApplicationSystemTestCase
  test "visiting the index in french" do
    visit("fr/layers")
    assert_selector "h1", text: "Couche"
  end
    test "visiting the index in en" do
      visit("en/layers")
      assert_selector "h1", text:"Layers"
  end
end
