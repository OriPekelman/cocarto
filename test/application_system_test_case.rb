require "test_helper"
require "capybara/cuprite"
require "ferrum_logger"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["CI"] == "true"
    # When using the browser in docker, we must pass the server’s url
    Capybara.app_host = "http://#{`hostname`.strip&.downcase}".freeze
    # and the server must bind from an other network
    Capybara.server_host = "0.0.0.0"
  end
  # In the CI, the browser is a chrome service not launched by cuprite
  ci_options = (ENV["CI"] == "true") ? {url: "http://browserless-chrome:3000"} : {}

  driven_by :cuprite, options: {logger: FerrumLogger.new, js_error: true}.merge(ci_options)

  def sign_in_as(user, password)
    visit user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: password
    click_button "Log in"

    assert_text "Maps"
  end

  def sign_out
    wait_until_dropdown_controller_ready
    find('[title="Settings"]').click
    click_button "Sign out"
    visit("/")
  end

  # We want to make sure that the dropdown controller is loaded
  # Otherwise capybara will click on the button, and nothing happens
  def wait_until_dropdown_controller_ready
    assert page.has_css?('[data-dropdown-loaded-value="true"]')
  end
end
