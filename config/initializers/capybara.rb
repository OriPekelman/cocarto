if Rails.env.test?
  require "capybara"

  Capybara.configure do |config|
    if ENV["CI"] == "true"
      # When using the browser in docker, we must pass the server’s url
      config.app_host = "http://#{`hostname`.strip&.downcase || "0.0.0.0"}".freeze
      # and the server must bind from an other network
      config.server_host = "0.0.0.0"
    end
  end
end
