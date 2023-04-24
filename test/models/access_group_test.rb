# == Schema Information
#
# Table name: access_groups
#
#  id         :uuid             not null, primary key
#  name       :text
#  role_type  :enum             not null
#  token      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  map_id     :uuid             not null
#
# Indexes
#
#  index_access_groups_on_map_id  (map_id)
#
# Foreign Keys
#
#  fk_rails_...  (map_id => maps.id)
#
require "test_helper"

class RoleTest < ActiveSupport::TestCase
  class Validations < RoleTest
    test "name required for token access_groups" do
      access_group = maps(:restaurants).access_groups.owner.new(token: AccessGroup.new_token)

      assert_not_predicate access_group, :valid?
      assert_equal [{error: :blank}], access_group.errors.details[:name]

      access_group.name = "My group"

      assert_predicate access_group, :valid?
    end

    test "name forbidden for user_specific access_groups" do
      access_group = maps(:restaurants).access_groups.owner.new(users: [users(:louise_michel)])

      assert_predicate access_group, :valid?

      access_group.name = "My group"

      assert_not_predicate access_group, :valid?
      assert_equal [{error: :present}], access_group.errors.details[:name]
    end

    test "only anonymous users for token access_groups" do
      access_group = maps(:restaurants).access_groups.owner.create(token: AccessGroup.new_token, name: "My group", users: [User.new])

      assert_predicate access_group, :valid?

      access_group.users = [users(:louise_michel)]

      assert_not_predicate access_group, :valid?
      assert_equal [{error: :present}], access_group.errors.details[:users]
    end

    test "only one user for user_specific access_groups" do
      access_group = maps(:restaurants).access_groups.owner.create(users: [users(:louise_michel)])

      assert_predicate access_group, :valid?

      access_group.users << users(:bakounine)

      assert_not_predicate access_group, :valid?
      assert_equal [{error: :equal_to, count: 1}], access_group.errors.details[:users]
    end

    test "user must have email for user_specific access_groups" do
      access_group = maps(:restaurants).access_groups.owner.create(users: [User.new])

      assert_not_predicate access_group, :valid?
      assert_equal [{error: :invalid}], access_group.errors.details[:users]
    end

    test "no two access groups for the same user and map" do
      access_group1 = maps(:restaurants).access_groups.owner.create(users: [users(:louise_michel)])

      assert_predicate access_group1, :valid?

      access_group2 = maps(:restaurants).access_groups.owner.create(users: [users(:louise_michel)])

      assert_not_predicate access_group2, :valid?
      assert_equal [{error: :unique_access_group, user_email: "louise.michel@commune.paris"}], access_group2.errors.details[:base]
    end

    test "last owner can’t kick themselves" do
      owner_role = access_groups("restaurants_reclus")
      owner_role.map.access_groups.excluding(owner_role).destroy_all # Make sure it’s the only role

      owner_role.destroy

      assert_not_predicate owner_role, :destroyed?
      assert_equal({map: [{error: :must_have_an_owner}]}, owner_role.errors.details)
    end

    test "last owner can’t demote themselves" do
      owner_role = access_groups("restaurants_reclus")
      owner_role.map.access_groups.excluding(owner_role).destroy_all # Make sure it’s the only role

      owner_role.update(role_type: :editor)

      assert_predicate owner_role, :has_changes_to_save?
      assert_equal({map: [{error: :must_have_an_owner}]}, owner_role.errors.details)
    end
  end
end
