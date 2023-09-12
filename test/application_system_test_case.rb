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

    assert_text "Signed in successfully"
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
    find ".header--container [data-dropdown-controller=connected]", wait: 10
  end

  def wait_until_map_loaded
    find ".maplibregl-map[data-loaded]", wait: 10
  end

  def wait_until_turbo_stream_connected
    # Turbo adds the `connected` attribute to <turbo-cable-stream-source> elements when the stream is up
    # We can rely on this to ensure row broadcasts from the backend are actually received.
    # (match: :first is needed because of turbo_stream_i18n_from. We can remove it after #196 if we stream empty frame-tags.)
    find "turbo-cable-stream-source[channel='Turbo::StreamsChannel'][connected]", match: :first, wait: 10
  end

  def rm_downloaded_file(name)
    downloads = Pathname.new(Capybara.save_path)
    File.delete(downloads.join(name))
  rescue
    nil
  end

  def wait_until_downloaded_file(name)
    downloads = Pathname.new(Capybara.save_path)
    Timeout.timeout(Capybara.default_max_wait_time) do
      break if downloads.glob("*.crdownload").blank? && File.exist?(downloads.join(name))
      sleep 0.1
    end

    assert_path_exists downloads.join(name)
  end
end
