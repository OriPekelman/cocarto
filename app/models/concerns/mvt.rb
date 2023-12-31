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
              COALESCE(rows.geom_web_mercator, territories.geom_web_mercator) AS geom,
              feature_id AS id,
              rows.id as original_id
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
              ST_AsMVTGeom(geom, ST_TileEnvelope(:z, :x, :y)) as geom,
              id,
              original_id
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
          ST_AsMVT(mvt_geom.*, :tile_layer_id, NULL, NULL, 'id') AS mvt
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

      case geometry_type
      when "point"
        [{
          id: layer_id + "--hover",
          source: layer_id,
          type: "circle",
          paint: {
            "circle-color": "#fff",
            "circle-radius": [
              "interpolate", ["linear"], ["zoom"],
              4, 2.5,
              6, 6,
              7, 8
            ],
            "circle-opacity": ["match", ["feature-state", "state"], "hover", 1, 0]
          },
          "source-layer": TILE_LAYER_ID
        },
          {
            id: layer_id,
            source: layer_id,
            type: "circle",
            paint: {
              "circle-color": color,
              "circle-radius": [
                "interpolate", ["linear"], ["zoom"],
                4, 1.5,
                6, 4.5,
                7, 6
              ]
            },
            "source-layer": TILE_LAYER_ID
          },
          {
            id: layer_id + "--outline",
            source: layer_id,
            type: "circle",
            paint: {
              "circle-stroke-color": "#fff",
              "circle-radius": [
                "interpolate", ["linear"], ["zoom"],
                5, 0,
                7, 4
              ],
              "circle-stroke-width": [
                "interpolate", ["linear"], ["zoom"],
                6.9, 0,
                7, 1
              ],
              "circle-opacity": 0
            },
            "source-layer": TILE_LAYER_ID
          }]
      when "line_string"
        [{
          id: layer_id + "--hover",
          source: layer_id,
          type: "line",
          paint: {
            "line-color": "#fff",
            "line-width": ["interpolate", ["linear"], ["zoom"],
              10, 6,
              20, 12],
            "line-opacity": ["match", ["feature-state", "state"], "hover", 1, 0]
          },
          "source-layer": TILE_LAYER_ID
        },
          {
            id: layer_id,
            source: layer_id,
            type: "line",
            paint: {
              "line-color": color,
              "line-width": ["interpolate", ["linear"], ["zoom"],
                10, 1.5,
                15, 3,
                20, 6]
            },
            "source-layer": TILE_LAYER_ID
          }]
      when "polygon", "territory"
        [{
          id: layer_id,
          source: layer_id,
          type: "fill",
          paint: {
            "fill-color": color,
            "fill-opacity": ["match", ["feature-state", "state"], "hover", 0.8, 0.1]
          },
          "source-layer": TILE_LAYER_ID
        },
          {
            id: layer_id + "--outline",
            source: layer_id,
            type: "line",
            paint: {
              "line-color": color,
              "line-width": ["interpolate", ["linear"], ["zoom"],
                10, 1.5,
                15, 3,
                20, 6]
            },
            "source-layer": TILE_LAYER_ID
          }]
      end
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
        style["layers"].concat(layer.maplibre_style)
      end

      style
    end
  end
end
