require "application_system_test_case"

class LoginTest < ApplicationSystemTestCase
  test "create an account" do
    visit("/?locale=en")
    click_link "Sign up"
    fill_in "user_email", with: "cabiai@amazonas.br"
    fill_in "user_password", with: "canne à sucre"
    fill_in "user_password_confirmation", with: "canne à sucre"
    click_button "Sign up"

    assert_button "cabiai@amazonas.br"

    wait_until_dropdown_controller_ready
    click_button "cabiai@amazonas.br"
    click_button "Sign out"
    click_link "Log in"
    fill_in "user_email", with: "cabiai@amazonas.br"
    fill_in "user_password", with: "canne à sucre"
    click_button "Log in"

    assert_button "cabiai@amazonas.br"
  end

  test "login and logout" do
    sign_in_as(users("reclus"), "refleurir")
    visit map_path(id: maps("boat"))

    assert_field "Name", with: "Boating trip"

    sign_out
    visit map_path(id: maps("boat"))

    assert_no_field "Name"
  end
end
