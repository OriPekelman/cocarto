require "test_helper"
require "capybara/cuprite"

# In the CI, the browser is a chrome service not launched by cuprite
def ci_options
  if ENV["CI"] == "true"
    {url: "http://browserless-chrome:3000"}
  else
    {}
  end
end

if ENV["CI"] == "true"
  # When using the browser in docker, we must pass the server’s url
  Capybara.app_host = "http://#{`hostname`.strip&.downcase || "0.0.0.0"}".freeze
  # and the server must bind from an other network
  Capybara.server_host = "0.0.0.0"
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, options: ci_options

  def sign_in_as(user, password)
    visit user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: password
    click_button "Log in"
    assert_no_text "Connexion"
  end
end
