# == Schema Information
#
# Table name: layers
#
#  id            :uuid             not null, primary key
#  geometry_type :enum             geometry, 0
#  name          :string
#  style         :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  map_id        :uuid             not null
#
# Indexes
#
#  index_layers_on_map_id  (map_id)
#
# Foreign Keys
#
#  fk_rails_...  (map_id => maps.id)
#
class Layer < ApplicationRecord
  # Constants
  COLORS = {
    blue: "#007AFF",
    cyan: "#32ADE6",
    indigo: "#5856D6",
    purple: "#AF52DE",
    green: "#34C759",
    brown: "#A2845E",
    pink: "#FF2D55",
    orange: "#FF9500"
  }

  # Attributes
  enum :geometry_type, {point: "point", line_string: "line_string", polygon: "polygon", territory: "territory"}, prefix: "geometry"

  # Relations
  belongs_to :map
  has_many :fields, dependent: :delete_all
  has_many :rows, -> { with_territory.order(:created_at) }, dependent: :delete_all, inverse_of: :layer # note: having a scope on the relation breaks statement caching and strict_loading
  has_and_belongs_to_many :territory_categories

  # Query as relations
  has_one :last_updated_row, -> { order(updated_at: :desc) }, class_name: "Row" # rubocop:disable Rails/InverseOf, Rails/HasManyOrHasOneDependent
  has_one :last_updated_row_author, through: :last_updated_row, source: :author

  # Hooks
  after_create_commit -> { broadcast_i18n_append_to map, target: dom_id(map, "layers") }
  after_update_commit -> { broadcast_i18n_replace_to map }
  after_destroy_commit -> { broadcast_remove_to map }

  def geo_feature_collection
    RGeo::GeoJSON::FeatureCollection.new(rows.map(&:geo_feature))
  end

  def color
    style["color"] || COLORS[:blue]
  end

  def color=(new_color)
    style["color"] = new_color
  end
end
