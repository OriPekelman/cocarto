# == Schema Information
#
# Table name: layers
#
#  id            :uuid             not null, primary key
#  geometry_type :enum             geometry, 0
#  name          :string
#  sort_order    :integer
#  style         :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  map_id        :uuid             not null
#
# Indexes
#
#  index_layers_on_map_id_and_sort_order  (map_id,sort_order) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (map_id => maps.id)
#
class Layer < ApplicationRecord
  include Mvt::LayerTiles
  include Mvt::LayerStyle

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
  has_many :fields, -> { rank(:sort_order) }, dependent: :destroy, inverse_of: :layer
  has_many :rows, dependent: :delete_all, inverse_of: :layer
  has_and_belongs_to_many :territory_categories
  has_many :import_mappings, class_name: "Import::Mapping", dependent: :destroy

  # Query as scopes
  scope :with_last_updated_row_id, -> do
    left_outer_joins(:rows)
      .order("layers.id, rows.updated_at DESC NULLS LAST")
      .select("DISTINCT ON (layers.id) layers.*, rows.id as computed_last_updated_row_id")
  end
  belongs_to :last_updated_row, class_name: "Row", optional: true, foreign_key: "computed_last_updated_row_id" # rubocop:disable Rails/InverseOf

  # Hooks
  after_create_commit -> { broadcast_i18n_append_to map, target: dom_id(map, "layers"), locals: {initially_active: true} }
  after_update_commit -> do
    html = ApplicationController.render(StatsFooterComponent.new(layer: self), layout: false)
    broadcast_i18n_replace_to map, target: dom_id(self, :stats), html: html
    broadcast_i18n_replace_to map, target: dom_id(self, :header), partial: "layers/table_header"
  end
  after_destroy_commit -> { broadcast_remove_to map }

  after_touch -> { @fields_by_id = nil }

  # Avoid querying the database when looking up a field by its ID
  def fields_by_id
    @fields_by_id ||= fields.index_by(&:id)
  end

  # Helper to preload rows fields values
  def rows_with_fields_values = rows.with_fields_values(self)

  def geometry_type_description
    Layer.human_attribute_name("geometry_type_description.#{geometry_type}")
  end

  def color
    style["color"] || COLORS[:blue]
  end

  def color=(new_color)
    style["color"] = new_color
  end

  # Dynamic Fields Associations
  # return all the names for the dynamic associations.
  # They can be used in `.includes` or `.preload`/`.eager_load` for the rows of this layer.
  def fields_association_names
    fields.type_territory.map(&:association_name)
  end
end
