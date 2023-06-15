require "application_system_test_case"

class FieldsTest < ApplicationSystemTestCase
  # Note / fun fact for the field names in the table headers:
  # Capybara sees the text as modified by `text-transform: uppercase`.
  # Even if the html is actually “Some Text”, we need to look for “SOME TEXT”.
  test "create, edit and destroy a field" do # rubocop:disable Minitest/MultipleAssertions
    sign_in_as(users("reclus"), "refleurir")
    visit map_path(id: maps("restaurants"))
    wait_until_map_loaded
    click_on "Display the table for this layer", match: :first

    # Create
    click_on "New column"
    fill_in "field[label]", with: "Un beau nombre"
    choose "Decimal"

    click_on "Save"

    assert_selector ".layer-table__th--field", text: "UN BEAU NOMBRE"

    # Edit
    find(".layer-table__th--field", text: "UN BEAU NOMBRE").click

    fill_in "field[label]", with: "Un nombre renommé"
    click_on "Save"

    refute_selector ".layer-table__th--field", text: "UN BEAU NOMBRE"
    assert_selector ".layer-table__th--field", text: "UN NOMBRE RENOMMÉ"

    # Destroy
    find(".layer-table__th--field", text: "TABLE SIZE").click

    within(".dropdown__content") do
      click_on "Delete"
    end

    refute_selector ".layer-table__th--field", text: "TABLE SIZE"
  end
end
