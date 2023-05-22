# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  email                  :string
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
    test "email presence or nil" do
      u1 = User.create(email: nil)
      u2 = User.create(email: "")

      assert_predicate u1, :persisted?
      assert_not_predicate u2, :persisted?
      assert_equal [{error: :blank}], u2.errors.details[:email]
    end

    test "email multiple nil is allowed" do
      u1 = User.create(email: nil)
      u2 = User.create(email: nil)

      assert_predicate u1, :persisted?
      assert_predicate u2, :persisted?
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
      assert_equal [{error: :"restrict_dependent_destroy.has_many", record: "rows"}], user.errors.details[:base]

      user.rows.destroy_all
      user.errors.clear
      user.destroy

      assert_not user.destroyed?
      assert_equal [{error: :"restrict_dependent_destroy.has_many", record: "maps"}], user.errors.details[:base]

      user.access_groups.destroy_all
      user.destroy

      assert_predicate user, :destroyed?
    end

    test "access group is copied when email is set" do
      user = User.create
      token_group = maps(:restaurants).access_groups.create(role_type: :viewer, name: "My group", token: AccessGroup.new_token, users: [user])

      assert_changes -> { token_group.users.count }, from: 1, to: 0 do
        user.update!(email: "email@example.com")
      end
      # a new user_specific access_group is created
      assert_equal 1, user.access_groups.size
      assert_nil user.access_groups.first.token
    end
  end

  class AssignAccessGroups < UserTest
    def create_group(role_type, user = nil)
      relation = maps(:restaurants).access_groups
      if user&.email.present?
        relation.create(role_type: role_type, users: [user])
      else
        relation.create(role_type: role_type, users: [user].compact, name: "A group name", token: AccessGroup.new_token)
      end
    end

    test "assign a group to an anonymous user" do
      # first group should be set, second should be ignored because it’s a lower type, last group should replace because it’s a promotion
      user = User.create

      editor_group = create_group("editor")
      assert_changes(-> { user.reload.access_group_ids }, from: [], to: [editor_group.id]) { user.assign_access_group(editor_group) }

      viewer_group = create_group("viewer")
      assert_no_changes(-> { user.reload.access_group_ids }) { user.assign_access_group(viewer_group) }

      owner_group = create_group("owner")
      assert_changes(-> { user.reload.access_group_ids }, from: [editor_group.id], to: [owner_group.id]) { user.assign_access_group(owner_group) }
    end

    test "assign a group to a named user" do
      # first group should be set, second should be ignored because it’s a lower type, last group should replace because it’s a promotion
      # Since this is a user with an email, a user-specific group is created, then modified.
      user = User.create(email: "a@a.a", password: "secret")

      editor_group = create_group("editor")
      assert_changes(-> { user.access_groups.pluck(:role_type) }, from: [], to: ["editor"]) { user.assign_access_group(editor_group) }

      viewer_group = create_group("viewer")
      assert_no_changes(-> { user.access_groups.pluck(:role_type) }) { user.assign_access_group(viewer_group) }

      new_group = create_group("owner")
      assert_changes(-> { user.access_groups.pluck(:role_type) }, from: ["editor"], to: ["owner"]) { user.assign_access_group(new_group) }
    end
  end
end
