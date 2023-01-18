require "test_helper"
require "capybara/cuprite"
require "ferrum_logger"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Allow connections from the local network
  Capybara.server_host = "0.0.0.0"
  # Run server in https (using a self-signed certificate, automatically with the localhost gem)
  Capybara.server = :puma, {Host: "ssl://#{Capybara.server_host}", Silent: true}
  # Specify the server hostname (the local machine) where the (remote) browser will connect.
  Capybara.app_host = "https://#{`hostname`.strip&.downcase}"

  driver_options = {logger: FerrumLogger.new, js_errors: true}
  # In the CI, the browser is a chrome service (not a process launched by cuprite)
  if ENV["CI"] == "true"
    driver_options[:url] = "http://browserless-chrome:3000"
  end

  driven_by :cuprite, options: driver_options

  setup do
    # Our self-signed certificate is invalid; make Chrome ignore this.
    # https://chromedevtools.github.io/devtools-protocol/tot/Security/#method-setIgnoreCertificateErrors
    # Note: this can be done with browser_options when running locally, because Cuprite/Ferrum launches a new Chrome process.
    # However in CI, we connect to an already-running browser, which we have to configure via the Chrome Devtools Protocol.
    Capybara.current_session.driver.browser.command("Security.setIgnoreCertificateErrors", ignore: true)
  end

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
