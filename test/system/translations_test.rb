require "application_system_test_case"

class TranslationsTest < ApplicationSystemTestCase
  test "visiting the index in both languages" do
    visit("/?locale=fr")
    assert_selector "a", text: "connexion"

    visit("/?locale=en")
    assert_selector "a", text: "Log in"
  end

  test "selecting an other language" do
    visit("/?locale=en")
    # We want to make sure that the dropdown controller is loaded
    # Otherwise capybara will click on the button, and nothing happens
    assert page.has_css?('[data-dropdown-loaded-value="true"]')
    click_button "Change language"
    click_link("Français")
    assert_link "connexion"
  end
end
