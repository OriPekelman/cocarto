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

  # Query as scopes
  scope :with_last_updated_row_id, -> do
    left_outer_joins(:rows)
      .order("maps.id, rows.updated_at DESC NULLS LAST")
      .select("DISTINCT ON (maps.id) maps.*, rows.id as computed_last_updated_row_id")
  end
  belongs_to :last_updated_row, class_name: "Row", optional: true, foreign_key: "computed_last_updated_row_id" # rubocop:disable Rails/InverseOf

  # Hooks
  after_update_commit do
    if name_previously_changed?
      broadcast_i18n_replace_to self, target: dom_id(self, :name), partial: "maps/name"
    end
  end

  def style(base_url)
    # The demotiles is very basic, only country borders
    # One must define a basemap as a maplibre style (e.g. from a provider such as maptiler)
    base_map = ENV["DEFAULT_MAP_STYLE"] || "https://demotiles.maplibre.org/style.json"
    style = JSON.parse(Net::HTTP.get(URI(base_map)))

    layers.each do |layer|
      style["sources"][dom_id(layer)] = layer.maplibre_source(base_url)
      style["layers"] << layer.maplibre_style
    end

    style
  end
end
