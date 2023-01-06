if Rails.env.test?
  require "capybara"

  Capybara.configure do |config|
    config.enable_aria_label = true
  end
end
