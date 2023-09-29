# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  admin                  :boolean          default(FALSE), not null
#  display_name           :string
#  email                  :string           not null
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
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable, :map_token_authenticatable

  include UserDeviseNotifications

  # The belongs_to :invited_by relation is added automatically by invitable
  has_many :invitations, class_name: "User", foreign_key: :invited_by_id, inverse_of: :invited_by, dependent: :nullify

  # Relations
  has_many :user_roles, inverse_of: :user, dependent: :destroy
  has_many :rows, foreign_key: :author_id, inverse_of: :author, dependent: :restrict_with_error

  # Through relations
  has_many :maps, through: :user_roles, dependent: :restrict_with_error

  # Validation
  validates :email, presence: true
  validates :admin, inclusion: [true, false]

  self.remember_for = 2.months

  def remember_me
    # Override from Devise::rememberable to enable it by default
    # See https://github.com/heartcombo/devise/issues/1513
    super.nil? ? true : super
  end

  # override from Devise::Models::DatabaseAuthenticatable
  def update_without_password(params, *options)
    params.delete(:email)
    super(params)
  end

  ## These methods are overridden in MapTokenAuthenticatable, for anonymous Users
  #
  def display_name
    super.presence || email&.split("@")&.first
  end

  def access_for_map(map)
    if map.new_record?
      map.user_roles.find { _1.user_id == id }
    else
      map.user_roles.find_by(user_id: id)
    end
  end

  # Assign a token group to the user; depending on the case, add the user to the group,
  # create a new user-specific group, or change the existing user-specific group.
  def assign_map_token(map_token)
    existing_role = user_roles.includes(:map_token).find_by(map: map_token.map)
    return if existing_role&.map_token == map_token

    map_token.increment!(:access_count) # rubocop:disable Rails/SkipsModelValidations

    if existing_role.nil? # self does not already have access to the map
      UserRole.create(map: map_token.map, role_type: map_token.role_type, user: self, map_token: map_token)
    elsif map_token.is_stronger_than(existing_role) # self already has a lower access to the map
      existing_role.update!(role_type: map_token.role_type, map_token: map_token)
    end
  end
end
