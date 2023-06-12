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
class UserRole < ApplicationRecord
  # Attributes
  include RoleType
  role_types_enum(ROLES)

  # Relationships
  belongs_to :user
  belongs_to :map
  belongs_to :map_token, optional: true

  accepts_nested_attributes_for :user

  # Validations
  validates :role_type, presence: true
  validates :user_id, uniqueness: {scope: :map_id}
  validate :user_is_not_anonymous

  # Hooks
  before_update :map_must_have_an_owner
  before_destroy :map_must_have_an_owner

  def user_is_not_anonymous
    errors.add(:user, :invalid) if user.anonymous?
  end

  def map_must_have_an_owner
    return if destroyed_by_association&.inverse_of&.name == :map
    return if map.user_roles.owner.where.not(id: self).exists?

    errors.add(:map, :must_have_an_owner)
    throw(:abort)
  end
end
