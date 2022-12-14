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

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, options: ci_options

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
