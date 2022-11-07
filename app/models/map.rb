# == Schema Information
#
# Table name: maps
#
#  id                :uuid             not null, primary key
#  default_latitude  :float
#  default_longitude :float
#  default_zoom      :float
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Map < ApplicationRecord
  # Relations
  has_many :access_groups, dependent: :destroy, inverse_of: :map
  has_many :layers, dependent: :destroy

  # Through relations
  has_many :users, through: :access_groups, inverse_of: :maps
  has_many :rows, through: :layers, inverse_of: :map

  # Query as relations
  has_one :layer_with_last_updated_row, -> { joins(:rows).order("rows.updated_at": :desc) }, class_name: "Layer" # rubocop:disable Rails/InverseOf, Rails/HasManyOrHasOneDependent
  has_one :last_updated_row, through: :layer_with_last_updated_row, source: :last_updated_row
  has_one :last_updated_row_author, through: :last_updated_row, source: :author
end
