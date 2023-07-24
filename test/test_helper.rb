ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

require "minitest/reporters"
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new if ENV["RM_INFO"].blank? # IntelliJ Minitest support conflicts with Minitest::Reporters

require "fixtures/fixtures_server"

class ActiveSupport::TestCase
  include FixturesServer

  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Use file fixtures as ActiveStorage attachments
  def attachable_fixture(filename)
    {io: file_fixture(filename).open, filename: filename, content_type: Mime[File.extname(filename)[1..]]}
  end

  # Use inline strings as ActiveStorage attachments
  def attachable_data(filename, data)
    {io: StringIO.new(data), filename: filename, content_type: Mime[File.extname(filename)[1..]]}
  end
end

class ActionDispatch::IntegrationTest
  # Make the Controllers tests run in english by default.
  # This also makes the url helper methods (e.g. `layer_url`) easier to use,
  # because the first parameter can be implicitly the model.
  def setup
    self.default_url_options = {locale: I18n.default_locale}
  end
end
