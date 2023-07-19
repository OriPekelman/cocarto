# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  admin                  :boolean          default(FALSE), not null
#  email                  :string           not null
#  encrypted_password     :string           default(""), not null
#  invitation_accepted_at :datetime
#  invitation_created_at  :datetime
#  invitation_limit       :integer
#  invitation_sent_at     :datetime
#  invitation_token       :string
#  invitations_count      :integer          default(0)
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  invited_by_id          :uuid
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_invitation_token      (invitation_token) UNIQUE
#  index_users_on_invited_by_id         (invited_by_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (invited_by_id => users.id)
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  class Validation < UserTest
    test "email presence" do
      u1 = User.create(email: "a@a.a", password: "secret")
      u2 = User.create(email: "", password: "secret")
      u3 = User.create(email: nil, password: "secret")

      assert_predicate u1, :persisted?
      assert_equal [{error: :blank}], u2.errors.details[:email]
      assert_equal [{error: :blank}], u3.errors.details[:email]
    end

    test "email uniqueness" do
      u1 = User.create(email: "a@a.a", password: "secret")
      u2 = User.create(email: "a@a.a", password: "secret2")

      assert_predicate u1, :persisted?
      assert_not_predicate u2, :persisted?
      assert_equal [{error: :taken, value: "a@a.a"}], u2.errors.details[:email]
    end
  end

  class Hooks < UserTest
    test "destroy" do # rubocop:disable Minitest/MultipleAssertions
      user = users(:reclus)
      user.destroy

      assert_not user.destroyed?

      # Add another owner to all reclus' maps
      maps(:restaurants).user_roles.owner.create(user: users(:cassini))
      user_roles(:boat_cassini).update(role_type: :owner)
      user.reload
      user.destroy

      assert_not user.destroyed?
      assert_equal [{error: :"restrict_dependent_destroy.has_many", record: "rows"}], user.errors.details[:base]

      user.rows.destroy_all
      user.reload
      user.destroy

      assert_predicate user, :destroyed?
    end
  end

  class AssignMapToken < UserTest
    def create_token(role_type)
      maps(:restaurants).map_tokens.create(role_type: role_type, name: "A link name")
    end

    test "assign a token to an anonymous user" do
      # first token should be set, second should be ignored because it’s a lower type, last token should replace because it’s a promotion
      user = MapTokenAuthenticatable::AnonymousUser.new
      user.tokens_array = []

      contributor_token = create_token(:contributor)
      assert_changes(-> { user.map_tokens.dup }, from: [], to: [contributor_token]) { user.assign_map_token(contributor_token) }

      viewer_token = create_token(:viewer)
      assert_no_changes(-> { user.map_tokens.dup }) { user.assign_map_token(viewer_token) }

      editor_token = create_token(:editor)
      assert_changes(-> { user.map_tokens.dup }, from: [contributor_token], to: [editor_token]) { user.assign_map_token(editor_token) }
    end

    test "assign a map token to a named user" do
      # first token should be set, second should be ignored because it’s a lower type, last token should replace because it’s a promotion
      # Since this is a user with an email, a user_role is created, then modified.
      user = User.create(email: "a@a.a", password: "secret")

      contributor_token = create_token(:contributor)
      assert_changes(-> { user.user_roles.pluck(:role_type) }, from: [], to: ["contributor"]) { user.assign_map_token(contributor_token) }

      viewer_token = create_token(:viewer)
      assert_no_changes(-> { user.user_roles.pluck(:role_type) }) { user.assign_map_token(viewer_token) }

      editor_token = create_token(:editor)
      assert_changes(-> { user.user_roles.pluck(:role_type) }, from: ["contributor"], to: ["editor"]) { user.assign_map_token(editor_token) }
    end
  end

  class ReassignFromAnonymousUser < UserTest
    test "reassign_from_anonymous_user" do
      anonymous_user = MapTokenAuthenticatable::AnonymousUser.new
      contributor_token = maps(:restaurants).map_tokens.contributor.create(name: "A link name")
      anonymous_user.tokens_array = [contributor_token.token]
      row = layers(:restaurants).rows.create!(author: anonymous_user, point: "POINT(0.0001 0.0001)")

      real_user = User.create(email: "a@a.a", password: "secret")
      real_user.reassign_from_anonymous_user(anonymous_user)

      assert_equal [maps(:restaurants)], real_user.maps
      assert_equal real_user, row.reload.author
      assert_nil row.anonymous_tag
    end
  end
end
