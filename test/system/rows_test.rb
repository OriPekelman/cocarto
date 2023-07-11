require "application_system_test_case"

class RowsTest < ApplicationSystemTestCase
  test "add a point to a layer" do
    sign_in_as(users("reclus"), "refleurir")

    visit map_path(id: maps("restaurants"))
    # We make sure to wait that the map is loaded
    map = wait_until_map_loaded
    click_on "Display the table for this layer", match: :first
    click_on "Add a point"

    assert_changes -> { layers(:restaurants).rows.count("*") }, from: 1, to: 2 do
      map.click
    end
  end

  test "add rows to the table" do # rubocop:disable Minitest/MultipleAssertions
    sign_in_as(users("reclus"), "refleurir")

    visit map_path(id: maps("restaurants"))
    map = wait_until_map_loaded

    # Open the layer table
    click_on "Display the table for this layer", match: :first

    assert_selector ".layer-container.is-active"
    assert_selector ".row", count: 1

    # Add a second point
    click_on "Add a point"
    map.click(x: 50, y: 0)

    assert_selector ".row", count: 2

    # Add a third point
    click_on "Add a point"
    map.click(x: 100, y: 0)

    assert_selector ".row", count: 3

    # Click on the map background
    map.click(x: 0, y: 100)

    assert_no_selector ".layer-table__tr--highlight"

    # Reselect the second point
    map.click(x: 50, y: 0)

    assert_selector ".layer-table__tr--highlight"

    # Close the layer table and deselect
    click_on "Display the table for this layer", match: :first
    map.click(x: 0, y: 100)

    assert_no_selector ".layer-container.is-active"
    assert_no_selector ".layer-table__tr--highlight"

    # Reselect the second point
    map.click(x: 50, y: 0)

    assert_selector ".layer-container.is-active"
    assert_selector ".layer-table__tr--highlight"
  end

  test "add a point from the rows/new form" do
    sign_in_as(users("reclus"), "refleurir")

    visit new_layer_row_path(layer_id: layers(:restaurants))

    fill_in "Name", with: "Le Bastringue"
    fill_in "Rating", with: "5"
    fill_in "Table Size", with: "9"

    # wait for the SearchComponent to be completely loaded
    assert_selector ".territory-search[data-controller='autocomplete dropdown'][data-autocomplete-controller=connected][data-dropdown-controller=connected]"

    # The territory suggestions are fetched when the query input changes;
    # See SearchComponent and autocomplete_controller.js
    # TODO: we need to tweak the autocomplete field identifier, "#q" is not sufficient.
    find("#q").native.send_keys("Paris")
    find("li", text: "Paris (75056) Île-de-France").click

    # The point location is set via js after the page is loaded; wait for the geojson field value to be set. (Also, it’s invisible.)
    # See views/rows/new.html.erb and map_add_point_controller.js
    find("#row_geojson[value*='{\"type\":\"Point\",\"coordinates\":']", visible: false)

    assert_changes -> { layers(:restaurants).rows.count }, from: 1, to: 2 do
      click_on "Add this point"
    end
  end

  test "edit a row" do
    sign_in_as(users("reclus"), "refleurir")

    visit layer_path(id: layers(:restaurants))

    assert_selector "input[value='L’Antipode']", count: 1

    find("input[value='L’Antipode']").set("Le Bastringue").native.send_keys(:return)

    assert_selector "input[value='Le Bastringue']", count: 1

    within("##{dom_id(rows(:antipode))}") do
      click_on "Edit…"
    end

    within(".modal") do
      find("input[value='Le Bastringue']").set("Le Hang’Art")
      click_on "Save"
    end

    assert_selector "input[value='Le Hang’Art']", count: 1
  end
end
