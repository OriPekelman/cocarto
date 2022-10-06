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
class AccessGroup < ApplicationRecord
  # Attributes
  enum :role_type, {owner: "owner", editor: "editor", contributor: "contributor", viewer: "viewer"}

  # Relationships
  has_and_belongs_to_many :users
  belongs_to :map

  accepts_nested_attributes_for :users

  # Validations
  validates :role_type, presence: true

  # Hooks
  before_destroy :map_must_have_an_owner

  def map_must_have_an_owner
    return if destroyed_by_association&.inverse_of&.name == :map
    return if map.access_groups.owner.where.not(id: self).exists?

    errors.add(:map, :must_have_an_owner)
    throw(:abort)
  end

  def build_dom_id
    if persisted?
      dom_id(self)
    elsif token.present?
      "new_access_group_by_token"
    else
      "new_access_group_by_email"
    end
  end
end
