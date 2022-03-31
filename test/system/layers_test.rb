require "application_system_test_case"

class LayersTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit layers_url

    assert_selector "h1", text: "Layers"
  end
end
