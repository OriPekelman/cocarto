# == Schema Information
#
# Table name: layers
#
#  id            :uuid             not null, primary key
#  geometry_type :enum             geometry, 0
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :uuid             not null
#
# Indexes
#
#  index_layers_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Layer < ApplicationRecord
  belongs_to :user
  has_many :fields, dependent: :delete_all
  has_many :row_contents, dependent: :delete_all
  enum enum_geometry_type: {point: :point, linestring: :linestring, polygon: :polygon, territory: :territory}
  validates :geometry_type, inclusion: {in: enum_geometry_types.keys}

  after_update_commit -> { broadcast_replace_to self, target: "layer-header", partial: "layers/name"}
end
