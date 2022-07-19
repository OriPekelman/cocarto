# == Schema Information
#
# Table name: roles
#
#  id         :uuid             not null, primary key
#  role_type  :enum             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  map_id     :uuid             not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_roles_on_map_id   (map_id)
#  index_roles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (map_id => maps.id)
#  fk_rails_...  (user_id => users.id)
#
class Role < ApplicationRecord
  # Attributes
  enum :role_type, {owner: "owner", editor: "editor", contributor: "contributor", viewer: "viewer"}

  # Relationships
  belongs_to :user, inverse_of: :roles
  belongs_to :map, inverse_of: :roles
end
