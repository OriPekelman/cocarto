require "application_system_test_case"

class RowsTest < ApplicationSystemTestCase
  test "add a point to a layer" do
    sign_in_as(users("reclus"), "refleurir")

    visit map_path(id: maps("restaurants"))
    # We make sure to wait that the map is loaded
    map = find ".maplibregl-map[data-loaded]", wait: 10
    click_on "Display the table for this layer", match: :first
    click_on "Add a point"

    assert_changes -> { layers(:restaurants).rows.count("*") }, from: 1, to: 2 do
      map.click
    end
  end
end
