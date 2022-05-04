require "application_system_test_case"

class LayersTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit ('fr/layers')

    assert_selector text: "Couche"
  end
end
