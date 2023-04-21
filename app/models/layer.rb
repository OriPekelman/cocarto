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
  has_many :fields, -> { order(:created_at) }, dependent: :destroy, inverse_of: :layer
  has_many :rows, dependent: :delete_all, inverse_of: :layer
  has_and_belongs_to_many :territory_categories

  # Query as scopes
  scope :with_last_updated_row_id, -> do
    left_outer_joins(:rows)
      .order("layers.id, rows.updated_at DESC NULLS LAST")
      .select("DISTINCT ON (layers.id) layers.*, rows.id as computed_last_updated_row_id")
  end
  belongs_to :last_updated_row, class_name: "Row", optional: true, foreign_key: "computed_last_updated_row_id" # rubocop:disable Rails/InverseOf

  # Helper to preload rows fields values
  def rows_with_fields_values = rows.with_fields_values(self)

  # Hooks
  after_create_commit -> { broadcast_i18n_append_to map, target: dom_id(map, "layers") }
  after_update_commit -> do
    html = ApplicationController.render(StatsFooterComponent.new(layer: self), layout: false)
    broadcast_i18n_replace_to map, target: dom_id(self, :stats), html: html
    broadcast_i18n_replace_to map, target: dom_id(self, :header), partial: "layers/table_header"
  end
  after_destroy_commit -> { broadcast_remove_to map }

  def color
    style["color"] || COLORS[:blue]
  end

  def color=(new_color)
    style["color"] = new_color
  end

  def as_mvt(x, y, z)
    sql = sanitized_select_as_mvt(x, y, z)
    records = ActiveRecord::Base.connection.execute(sql)
    ActiveRecord::Base.connection.unescape_bytea(records[0]["mvt"])
  end

  # Dynamic Fields Associations
  # return all the names for the dynamic associations.
  # They can be used in `.includes` or `.preload`/`.eager_load` for the rows of this layer.
  def fields_association_names
    fields.type_territory.map(&:association_name)
  end

  private

  def sanitized_select_as_mvt(x, y, z)
    query = <<-SQL
      WITH
        -- first select the geometries that might be in the tiles
        geoms AS (
          SELECT
            COALESCE(rows.geom_web_mercator, territories.geom_web_mercator) AS geom
          FROM
            rows
          LEFT JOIN
            territories ON territories.id = rows.territory_id
          WHERE
            rows.layer_id = :layer_id
        ),

        -- transform those geometries into the right format for MVT
        mvt_geom AS (
          SELECT
            ST_AsMVTGeom(geom, ST_TileEnvelope(:z, :x, :y))
          FROM
            geoms
          WHERE
            -- the `&&` operator compares the bounding box of the two geometries using the spatial index
            -- this where condition won’t change the end result, but will improve the performances
            geom && ST_TileEnvelope(:z, :x, :y)
        )

      SELECT
        -- generate the tile
        -- the parameter of ST_AsMVT must be rows, not records
        -- that is why we must do sub-requests
        ST_AsMVT(mvt_geom.*, 'layer') AS mvt
      FROM
        mvt_geom
    SQL

    Layer.sanitize_sql_array([query, x: x, y: y, z: z, layer_id: id])
  end
end
