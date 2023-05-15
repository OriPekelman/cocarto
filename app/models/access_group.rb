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
  validates :token, presence: true, allow_nil: true # token is either nil or set, never blank
  validates :name, presence: true, if: -> { token.present? }
  validates :name, absence: true, if: -> { token.blank? }
  validate :either_token_or_user_specific
  validate :user_map_access_uniqueness

  def either_token_or_user_specific
    errors.add(:users, :present) if token.present? && users.with_email.exists?
    errors.add(:users, :equal_to, count: 1) if token.nil? && users.size != 1
    errors.add(:users, :invalid) if token.nil? && users.first&.email.nil?
  end

  def user_map_access_uniqueness
    users.each do |user|
      if map.access_groups.merge(user.access_groups).where.not(id: self).exists?
        errors.add(:base, :unique_access_group, user_email: user.email)
      end
    end
  end

  # Hooks
  before_update :map_must_have_an_owner
  before_destroy :map_must_have_an_owner

  def map_must_have_an_owner
    return if destroyed_by_association&.inverse_of&.name == :map
    return if map.access_groups.owner.where.not(id: self).exists?

    errors.add(:map, :must_have_an_owner)
    throw(:abort)
  end

  # Scopes
  scope :with_token, -> { where.not(token: nil) }
  scope :user_specific, -> { where(token: nil) }

  def self.new_token
    Devise.friendly_token.first(16)
  end
end
