# == Schema Information
#
# Table name: territory_categories
#
#  id         :uuid             not null, primary key
#  name       :string
#  revision   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_territory_categories_on_name_and_revision  (name,revision) UNIQUE
#
class TerritoryCategory < ApplicationRecord
  has_many :territories, -> { with_geojson.limit(1000) }, dependent: :destroy, inverse_of: :territory_category
end
