class TerritoryCategory < ApplicationRecord
  has_many :territories, -> { with_geojson.limit(1000) }
end
