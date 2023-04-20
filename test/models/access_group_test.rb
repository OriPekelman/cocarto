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
