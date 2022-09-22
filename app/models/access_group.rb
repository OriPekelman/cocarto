# == Schema Information
#
# Table name: access_groups
#
#  id         :uuid             not null, primary key
#  role_type  :enum             not null
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

  before_destroy :map_must_have_an_owner

  def map_must_have_an_owner
    return if map.access_groups.owner.where.not(id: self).exists?

    errors.add(:map, :must_have_an_owner)
    throw(:abort)
  end
end
