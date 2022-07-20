# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable

  # The belongs_to :invited_by relation is added automatically by invitable
  has_many :invitations, class_name: "User", foreign_key: :invited_by, inverse_of: :invited_by, dependent: :nullify

  # Relationships
  has_many :roles, dependent: :restrict_with_error, inverse_of: :user

  # Through relationships
  has_many :maps, through: :roles, inverse_of: :users
end
