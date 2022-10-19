require "test_helper"

class PresenceTrackerChannelTest < ActionCable::Channel::TestCase
  class AuthorizationTests < PresenceTrackerChannelTest
    test "authorized user can connect to the presence channel" do
      stub_connection current_user: users(:cassini)
      subscribe layer: layers(:hiking).id
      assert_predicate subscription, :confirmed?
    end

    test "unauthorized user cannot connect to the presence channel" do
      stub_connection current_user: users(:reclus)
      assert_raises(Pundit::NotAuthorizedError) { subscribe(layer: layers(:hiking).id) }
    end
  end

  class ActionTests < PresenceTrackerChannelTest
    setup do
      stub_connection current_user: users(:cassini)
      subscribe layer: layers(:hiking).id
    end

    test "mouse_moved is broad_cast" do
      assert_broadcast_on layers(:hiking), some: :data, action: :mouse_moved do
        perform :mouse_moved, some: :data
      end
    end
  end
end
