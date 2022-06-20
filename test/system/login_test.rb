require "application_system_test_case"

class TranslationsTest < ApplicationSystemTestCase
  test "create an accout" do
    visit("/?locale=en")
    click_link "Sign up"
    fill_in "user_email", with: "cabiai@amazonas.br"
    fill_in "user_password", with: "canne à sucre"
    fill_in "user_password_confirmation", with: "canne à sucre"
    click_button "Sign up"
    assert_selector "span", text: "cabiai@amazonas.br"

    find("span", text: "cabiai@amazonas.br").click
    click_button "Sign out"
    click_link "Log in"
    fill_in "user_email", with: "cabiai@amazonas.br"
    fill_in "user_password", with: "canne à sucre"
    click_button "Log in"
    assert_selector "span", text: "cabiai@amazonas.br"
  end
end
