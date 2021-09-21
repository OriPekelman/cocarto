class Table < ApplicationRecord
    has_many :fields
    enum enum_geometry_type: { point: :point, linestring: :linestring, polygon: :polygon }
    validates :geometry_type, inclusion: { in: enum_geometry_types.keys }
end
