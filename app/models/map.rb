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
  # Relations
  has_many :access_groups, dependent: :destroy, inverse_of: :map
  has_many :layers, dependent: :destroy

  # Through relations
  has_many :users, through: :access_groups, inverse_of: :maps
  has_many :rows, through: :layers, inverse_of: :map
end
