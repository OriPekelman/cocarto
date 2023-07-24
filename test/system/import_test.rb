require "application_system_test_case"

class ImportTest < ApplicationSystemTestCase
  class FileImportTest < ImportTest
    test "import from a csv file" do  # rubocop:disable Minitest/MultipleAssertions
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

      click_on "Import…"
      attach_file("file", file_fixture("touladi.png").to_path, make_visible: true)
      click_on "Import"

      assert_text "1 error prohibited this data import from being saved:"
      assert_text "This source type is not supported."
    end
  end

  class ServerImportTest < ImportTest
    setup { start_fixtures_server }

    test "import from a wfs server" do  # rubocop:disable Minitest/MultipleAssertions
      sign_in_as(users("cassini"), "générations12345")
      visit layer_path(id: layers("hiking_paths"))
      wait_until_turbo_stream_connected

      # Reimport restaurants (with the Name as the key)
      click_on "Import…"
      fill_in "URL of a WFS server", with: "#{fixtures_server_url}/wfs"
      fill_in "Layer name (Feature Type)", with: "TEST_FEATURE_NAME"
      click_on "Import"

      assert_text "Import successful"
      assert_text "Imported 4 rows"

      click_on "OK"

      assert_selector "input[value='Tracé numéro un']", count: 1
    end
  end
end
