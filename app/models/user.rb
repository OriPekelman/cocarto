# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  email                  :string
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
    :recoverable, :rememberable, :validatable

  # The belongs_to :invited_by relation is added automatically by invitable
  has_many :invitations, class_name: "User", foreign_key: :invited_by_id, inverse_of: :invited_by, dependent: :nullify

  # Relations
  has_many :rows, foreign_key: :author_id, inverse_of: :author, dependent: :restrict_with_error
  has_and_belongs_to_many :access_groups, inverse_of: :users

  # Through relations
  has_many :maps, through: :access_groups, dependent: :restrict_with_error

  # Validation
  validates :email, presence: true, allow_nil: true
  def email_required? = false # Disable default devise presence validation

  scope :with_email, -> { where.not(email: nil) }
  scope :without_email, -> { where(email: nil) }

  # Hooks
  before_update :copy_access_groups

  def copy_access_groups
    if email_changed?(from: nil)
      access_groups.includes(:map, :users).with_token.each do |access_group|
        access_group.users.destroy(self)
        AccessGroup.create(map: access_group.map, role_type: access_group.role_type, users: [self])
      end
    end
  end

  # Devise overrides
  def password_required?
    false
  end

  self.remember_for = 2.months

  def remember_me
    # Override from Devise::rememberable to enable it by default
    # See https://github.com/heartcombo/devise/issues/1513
    super.nil? ? true : super
  end

  def display_name
    if email
      email.split("@")[0]
    else
      I18n.t("users.anonymous")
    end
  end
end
