# == Schema Information
#
# Table name: maps
#
#  id         :uuid             not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Map < ApplicationRecord
  # Relationships
  has_many :roles, dependent: :destroy
  has_many :layers, dependent: :destroy

  # Through relationships
  has_many :users, through: :roles
end
