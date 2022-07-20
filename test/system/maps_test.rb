require "application_system_test_case"

class MapsTest < ApplicationSystemTestCase
  test "create and destroy a map" do
    sign_in_as(users("reclus"), "refleurir")

    visit new_map_path
    fill_in "Name", with: "Test de nouvelle carte"
    click_button "Create a map"
    fill_in "Name", with: "Test de nouvelle couche"
    click_button "Create a layer"
    click_link "map"
    accept_confirm do
      click_link "Delete map"
    end
    assert_text "The map was successfully destroyed"
  end

  test "visit an existing owned map" do
    sign_in_as(users("reclus"), "refleurir")

    visit map_path(id: maps("restaurants"))
    assert_text "Restaurants"
  end

  test "visit an unpermitted map" do
    sign_in_as(users("reclus"), "refleurir")

    visit map_path(id: maps("hiking"))
    assert_text "You are not authorized to perform this action."
  end
end
