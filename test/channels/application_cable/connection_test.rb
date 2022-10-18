require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  test "connects with warden" do
    connect env: {"warden" => OpenStruct.new(user: users(:cassini))}

    assert_equal "cassini@carto.gouv.fr", connection.current_user.email
  end
end
