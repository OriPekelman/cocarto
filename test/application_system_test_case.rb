require "test_helper"
require "capybara/cuprite"
require "ferrum_logger"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Wait for at most DOWNLOAD_TIMEOUT seconds until all downloads are finished
  DOWNLOAD_TIMEOUT = 10
  # Allow connections from the local network
  Capybara.server_host = "0.0.0.0"
  # Run server in https (using a self-signed certificate, automatically with the localhost gem)
  Capybara.server = :puma, {Host: "ssl://#{Capybara.server_host}", Silent: true}
  # Specify the server hostname (the local machine) where the (remote) browser will connect.
  Capybara.app_host = "https://#{`hostname`.strip&.downcase}"
  # Where will capybara save screenshots, downloaded files…
  Capybara.save_path = ENV.fetch("CAPYBARA_ARTIFACTS", "./tmp/capybara")

  driver_options = {logger: FerrumLogger.new, js_errors: true}
  # In the CI, the browser is a chrome service (not a process launched by cuprite)
  if ENV["CI"] == "true"
    driver_options[:url] = "http://browserless-chrome:3000"
  end
  # On mac, chrome headless breaks webgl since version 109.
  # Using --enable-gpu, --use-gl --use-angle does not seem to help.
  # https://bugs.chromium.org/p/chromium/issues/detail?id=765284
  if ENV["COCARTO_DEBUG_WORKAROUND_HEADLESS_CHROME_WEBGL_MAC"].present?
    driver_options[:headless] = false
    driver_options[:browser_options] = {"accept-lang" => "en"}
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

  def wait_all_downloads
    downloads = Pathname.new(Capybara.save_path)
    Timeout.timeout(DOWNLOAD_TIMEOUT) do
      sleep 0.1 until downloads.glob("*.crdownload").blank?
    end
  end
end
