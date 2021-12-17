class Layer < ApplicationRecord
  has_many :fields, dependent: :delete_all
  has_many :points, dependent: :delete_all
  has_many :row_contents, dependent: :delete_all
  enum enum_geometry_type: {point: :point, linestring: :linestring, polygon: :polygon}
  validates :geometry_type, inclusion: {in: enum_geometry_types.keys}
end
