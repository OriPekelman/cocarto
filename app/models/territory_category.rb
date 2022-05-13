class TerritoryCategory < ApplicationRecord
  has_many :territories, -> { with_geojson }
end
