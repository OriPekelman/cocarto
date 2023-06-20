require "application_system_test_case"

class ImportTest < ApplicationSystemTestCase
  test "import stuff" do  # rubocop:disable Minitest/MultipleAssertions
    sign_in_as(users("reclus"), "refleurir")
    visit layer_path(id: layers("restaurants"))
    wait_until_turbo_stream_connected

    # Check that row is not present yet
    assert_selector "input[value='L’Antipode']", count: 1
    refute_selector "input[value='Le Bastringue']"

    # Reimport restaurants (with the Name as the key)
    click_on "Import…"
    attach_file("file", file_fixture("restaurants.csv").to_path, make_visible: true)
    find(".form__details-summary").click
    select "Name", from: "ID column"
    click_on "Import"

    assert_text "Import successful"
    assert_text "Imported 2 rows"

    click_on "OK"

    assert_selector "input[value='L’Antipode']", count: 1
    assert_selector "input[value='Le Bastringue']", count: 1
  end

  test "import failure" do  # rubocop:disable Minitest/MultipleAssertions
    sign_in_as(users("reclus"), "refleurir")
    visit layer_path(id: layers("restaurants"))
    wait_until_turbo_stream_connected

    # Import restaurants (with the Name as the key)
    click_on "Import…"
    attach_file("file", file_fixture("touladi.png").to_path, make_visible: true)
    click_on "Import"

    assert_text "Import failed"
    assert_text "Invalid byte sequence in UTF-8 in line 1."
  end
end
