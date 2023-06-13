# == Schema Information
#
# Table name: map_tokens
#
#  id           :uuid             not null, primary key
#  access_count :integer          default(0), not null
#  name         :text             not null
#  role_type    :enum             not null
#  token        :text             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  map_id       :uuid             not null
#
# Indexes
#
#  index_map_tokens_on_map_id  (map_id)
#  index_map_tokens_on_token   (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (map_id => maps.id)
#
class MapToken < ApplicationRecord
  # Attributes
  include RoleType
  role_types_enum(ROLES - %w[owner])

  attribute :token, :string, default: -> { Devise.friendly_token.first(16) }

  # Relationships
  belongs_to :map
  has_many :user_roles, dependent: :nullify

  # Validations
  validates :role_type, presence: true
  validates :token, presence: true
  validates :name, presence: true
  validates :access_count, presence: true
  validate :prevent_changing_token, on: :update

  def prevent_changing_token
    errors.add(:token, :cant_be_changed) if token_changed?
  end
end
