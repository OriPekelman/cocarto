require "application_system_test_case"

class LoginTest < ApplicationSystemTestCase
  test "create an account" do
    visit("/?locale=en")
    click_link "Sign up"
    fill_in "user_email", with: "cabiai@amazonas.br"
    fill_in "user_password", with: "canne à sucre"
    fill_in "user_password_confirmation", with: "canne à sucre"
    click_button "Sign up"

    assert_button "cabiai"

    wait_until_dropdown_controller_ready
    click_button "cabiai"
    click_button "Sign out"
    click_link "Log in"
    fill_in "user_email", with: "cabiai@amazonas.br"
    fill_in "user_password", with: "canne à sucre"
    click_button "Log in"

    assert_button "cabiai"
  end

  test "login and logout" do
    sign_in_as(users("reclus"), "refleurir")
    visit map_path(id: maps("boat"))

    assert_selector "h2", text: "Boating trip"

    sign_out
    visit map_path(id: maps("boat"))

    assert_no_field "Name"
  end

  test "redirection after signin" do # rubocop:disable Minitest/MultipleAssertions
    visit map_path(id: maps("boat"))

    assert_text "You need to sign in or sign up before continuing."
    assert_current_path user_session_path

    fill_in "user_email", with: users("reclus").email
    fill_in "user_password", with: "refleurir"
    click_button "Log in"

    assert_selector "h2", text: "Boating trip"
    assert_current_path map_path(id: maps("boat"))
  end
end
