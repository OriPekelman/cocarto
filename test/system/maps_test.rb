require "application_system_test_case"

class MapsTest < ApplicationSystemTestCase
  test "create and destroy a map" do
    sign_in_as(users("reclus"), "refleurir")

    visit new_map_path
    fill_in "Name", with: "Test de nouvelle carte"
    click_button "Create a map"
    fill_in "Name", with: "Test de nouvelle couche"
    click_button "Create a layer"
    accept_confirm do
      click_link "Delete this map"
    end

    assert_text "The map was successfully destroyed"
    assert_no_text "Test de nouvelle carte"
  end

  test "visit an existing owned map" do
    sign_in_as(users("reclus"), "refleurir")

    visit map_path(id: maps("restaurants"))

    assert_field "Name", with: "Restaurants"
  end

  test "visit an unpermitted map" do
    sign_in_as(users("reclus"), "refleurir")

    visit map_path(id: maps("hiking"))

    assert_text "You are not authorized to perform this action."
  end

  test "download as an image" do
    sign_in_as(users("reclus"), "refleurir")

    visit map_path(id: maps("restaurants"))
    wait_until_map_loaded
    click_link "Export as image", href: nil
    wait_all_downloads

    assert_path_exists("#{Capybara.save_path}/Restaurants.png")
  end
end
