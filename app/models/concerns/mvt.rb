# MVT stands for Mapbox Vector Tiles
# It contains data that wil be rendered by maplibre-gl-js according to a style
# This concern contains the functions to generate the Vector Tiles and the style to render them
module Mvt
  # Name of the layer in the tile
  # We use one tileset per layer to allow a fine grained refreshing of the tiles when geometries change
  # Because we use one tileset per layer, it’s always the same name
  TILE_LAYER_ID = "layer"
  module LayerTiles
    def as_mvt(x, y, z)
      sql = sanitized_select_as_mvt(x, y, z)
      records = ActiveRecord::Base.connection.execute(sql)
      ActiveRecord::Base.connection.unescape_bytea(records[0]["mvt"])
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
          ST_AsMVT(mvt_geom.*, :tile_layer_id) AS mvt
        FROM
          mvt_geom
      SQL

      Layer.sanitize_sql_array([query, x: x, y: y, z: z, layer_id: id, tile_layer_id: TILE_LAYER_ID])
    end
  end

  module LayerStyle
    def maplibre_source(base_url)
      {
        type: "vector",
        tiles: ["#{base_url}/#{id}/mvt/{z}/{x}/{y}"]
      }
    end

    def maplibre_style
      layer_id = dom_id(self)

      type = {
        "point" => "circle",
        "line_string" => "line",
        "polygon" => "fill",
        "territory" => "fill"
      }[geometry_type]

      paint = case geometry_type
      when "point"
        {
          "circle-color": color,
          "circle-radius": 6
        }
      when "line_string"
        {
          "line-color": color,
          "line-width": 2
        }
      when "polygon", "territory"
        {
          "fill-color": color,
          "fill-opacity": 0.5
        }
      end

      {
        id: layer_id,
        source: layer_id,
        type: type,
        paint: paint,
        "source-layer": TILE_LAYER_ID
      }
    end
  end

  module MapStyle
    def style(base_url)
      # The demotiles is very basic, only country borders
      # One must define a basemap as a maplibre style (e.g. from a provider such as maptiler)
      base_map = ENV["DEFAULT_MAP_STYLE"] || "https://demotiles.maplibre.org/style.json"
      json = Rails.cache.fetch(base_map, expires_in: 24.hours) { Net::HTTP.get(URI(base_map)) }
      style = JSON.parse(json)

      layers.each do |layer|
        style["sources"][dom_id(layer)] = layer.maplibre_source(base_url)
        style["layers"] << layer.maplibre_style
      end

      style
    end
  end
end
