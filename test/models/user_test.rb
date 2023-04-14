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
      u1 = User.create(email: "a@a.a")
      u2 = User.create(email: "a@a.a")

      assert_predicate u1, :persisted?
      assert_not_predicate u2, :persisted?
      assert_equal [{error: :taken, value: "a@a.a"}], u2.errors.details[:email]
    end
  end

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
end
