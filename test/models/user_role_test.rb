# == Schema Information
#
# Table name: user_roles
#
#  id           :uuid             not null, primary key
#  role_type    :enum             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  map_id       :uuid             not null
#  map_token_id :uuid
#  user_id      :uuid             not null
#
# Indexes
#
#  index_user_roles_on_map_id_and_user_id  (map_id,user_id) UNIQUE
#  index_user_roles_on_map_token_id        (map_token_id)
#  index_user_roles_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (map_id => maps.id)
#  fk_rails_...  (map_token_id => map_tokens.id)
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class UserRoleTest < ActiveSupport::TestCase
  class Validations < UserRoleTest
    test "last owner can’t kick themselves" do
      owner_role = user_roles("restaurants_reclus")
      owner_role.map.user_roles.excluding(owner_role).destroy_all # Make sure it’s the only role

      owner_role.destroy

      assert_not_predicate owner_role, :destroyed?
      assert_equal({map: [{error: :must_have_an_owner}]}, owner_role.errors.details)
    end

    test "last owner can’t demote themselves" do
      owner_role = user_roles("restaurants_reclus")
      owner_role.map.user_roles.excluding(owner_role).destroy_all # Make sure it’s the only role

      owner_role.update(role_type: :editor)

      assert_predicate owner_role, :has_changes_to_save?
      assert_equal({map: [{error: :must_have_an_owner}]}, owner_role.errors.details)
    end
  end
end
