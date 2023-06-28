module ImportExport
  class ImporterBase
    module GeometryParsing
      class ImportGeometryError < StandardError; end

      PARSERS = {
        geojson: ->(value) { RGeo::GeoJSON.decode(value, geo_factory: RGEO_FACTORY) },
        wkt: ->(value) { RGEO_FACTORY.parse_wkt(value) },
        wkb: ->(value) { RGEO_FACTORY.parse_wkb(value) },
        xy: ->(x, y) { RGEO_FACTORY.point(x, y) }
      }

      def extract_geometry(values, geometry_keys, geometry_format) # mutates the passed values hash, raises ImportGeometryError
        geometry_values = values.values_at(*geometry_keys).compact
        return if geometry_values.size != Array(geometry_keys).size

        geometry = PARSERS[geometry_format].call(*geometry_values)
        Array(geometry_keys).each { values.delete(_1) } if geometry

        geometry
      rescue JSON::ParserError, RGeo::Error::ParseError
        raise ImportGeometryError
      end

      STRATEGIES = [
        ["geojson", :geojson],
        ["wkt", :wkt],
        ["wkb", :wkb],
        ["geometry", :geojson],
        ["geometry", :wkt],
        ["geometry", :wkb],
        ["geom", :geojson],
        ["geom", :wkt],
        ["geom", :wkb],
        [%w[longitude latitude], :xy],
        [%w[long lat], :xy],
        [%w[lon lat], :xy],
        [%w[lng lat], :xy],
        [%w[x y], :xy]
      ]

      def guess_geometry(values)
        geometry = nil
        STRATEGIES.each do |strategy|
          geometry = extract_geometry(values, Array(strategy.first), strategy.second)
          break if geometry
        rescue ImportGeometryError
          # Ignore error when guessing
        end

        geometry
      end
    end
  end
end
