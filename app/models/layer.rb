# == Schema Information
#
# Table name: layers
#
#  id            :uuid             not null, primary key
#  geometry_type :enum             geometry, 0
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  map_id        :uuid             not null
#  user_id       :uuid             not null
#
# Indexes
#
#  index_layers_on_map_id   (map_id)
#  index_layers_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (map_id => maps.id)
#  fk_rails_...  (user_id => users.id)
#
class Layer < ApplicationRecord
  belongs_to :user
  has_many :fields, dependent: :delete_all
  has_many :rows, dependent: :delete_all
  enum enum_geometry_type: {point: :point, linestring: :linestring, polygon: :polygon, territory: :territory}
  validates :geometry_type, inclusion: {in: enum_geometry_types.keys}

  after_update_commit -> { broadcast_replace_to self, target: "layer-header", partial: "layers/name" }

  def geo_feature_collection
    RGeo::GeoJSON::FeatureCollection.new(rows.map(&:geo_feature))
  end
end
