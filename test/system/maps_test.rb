require "application_system_test_case"

class MapsTest < ApplicationSystemTestCase
  test "create and destroy a map" do
    sign_in_as(users("reclus"), "refleurir")

    click_on "Create a new map"
    fill_in "map[name]", with: "Test de nouvelle carte"
    fill_in "map[layers_attributes][0][name]", with: "Test de nouvelle couche"
    click_button "Save"

    click_link "Test de nouvelle carte"
    accept_confirm do
      click_button "Delete"
    end

    assert_text "Map destroyed."
    assert_no_text "Test de nouvelle carte"
  end

  test "access only permitted map" do
    sign_in_as(users("reclus"), "refleurir")

    # restaurants is owned by reclus
    visit map_path(id: maps("restaurants"))

    assert_selector "h2", text: "Restaurants"

    # The layer is open and we can see its content
    assert_text "L’Antipode"

    # reclus has no access to hiking
    visit map_path(id: maps("hiking"))

    assert_text "You are not authorized to perform this action."
  end

  test "download as an image" do
    rm_downloaded_file("Restaurants.png")

    sign_in_as(users("reclus"), "refleurir")

    visit map_path(id: maps("restaurants"))
    wait_until_map_loaded
    click_link "Export as image", href: nil

    wait_until_downloaded_file("Restaurants.png")
  end
end
