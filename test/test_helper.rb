ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new if ENV["RM_INFO"].blank? # IntelliJ Minitest support conflicts with Minitest::Reporters

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionDispatch::IntegrationTest
  # Make the Controllers tests run in english by default.
  # This also makes the url helper methods (e.g. `layer_url`) easier to use,
  # because the first parameter can be implicitly the model.
  def setup
    self.default_url_options = {locale: I18n.default_locale}
  end
end
