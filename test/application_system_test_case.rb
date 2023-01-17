require "test_helper"
require "capybara/cuprite"
require "ferrum_logger"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  Capybara.server_host = "0.0.0.0" # Allow connections from the local network
  # SSL stuff, WIP
  # Capybara.server_port = 3001 # this can be left unspecified
  Capybara.server = :puma, {Host: "ssl://#{Capybara.server_host}"} # TODO Add Silent: true
  # Specify the server hostname where the (remote) browser will connect
  Capybara.app_host = "https://#{`hostname`.strip&.downcase}" # % Capybara.server_port
  # Capybara.app_host = "https://#{"127.0.0.1".strip&.downcase}:%d" % Capybara.server_port # <- this works with allow-insecure-localhost

  driver_options = {
    logger: FerrumLogger.new, js_error: true,
    browser_options: {
      # "allow-insecure-localhost" => nil, # this works when connecting to 127.0.0.1
      # "ignore-certificate-errors-spki-list" => nil # this needs something from the localhost gem
      # "ignore-certificate-errors" => nil # this is undocumented? but works locally (when connecting by hostname)
    }
  }

  if ENV["CI"] == "true"
    # In the CI, the browser is a chrome service not launched by cuprite
  driver_options.merge!({url: "http://browserless-chrome:3000"})
  end

  driven_by :cuprite, options: driver_options

  def sign_in_as(user, password)
    page.driver.browser.command("Security.setIgnoreCertificateErrors", ignore: true)
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
