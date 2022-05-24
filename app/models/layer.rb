# == Schema Information
#
# Table name: layers
#
#  id            :uuid             not null, primary key
#  geometry_type :enum             geometry, 0
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Layer < ApplicationRecord
  has_many :fields, dependent: :delete_all
  has_many :row_contents, dependent: :delete_all
  enum enum_geometry_type: {point: :point, linestring: :linestring, polygon: :polygon}
  validates :geometry_type, inclusion: {in: enum_geometry_types.keys}
end
