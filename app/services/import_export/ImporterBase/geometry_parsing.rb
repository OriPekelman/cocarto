module ImportExport
  class ImporterBase
    module GeometryParsing
      PARSERS = {
        geojson: ->(value) { RGeo::GeoJSON.decode(value, geo_factory: RGEO_FACTORY) },
        wkt: ->(value) { RGEO_FACTORY.parse_wkt(value) },
        wkb: ->(value) { RGEO_FACTORY.parse_wkb(value) },
        xy: ->(x, y) { RGEO_FACTORY.point(x, y) }
      }

      def extract_geometry(values, geometry_keys, geometry_format) # mutates the passed values hash
        geometry_values = values.values_at(*geometry_keys).compact
        return if geometry_values.size != Array(geometry_keys).size

        geometry = PARSERS[geometry_format].call(*geometry_values)
        Array(geometry_keys).each { values.delete(_1) } if geometry

        geometry
      rescue JSON::ParserError, RGeo::Error::ParseError
        # TODO: error reporting
      end
    end
  end
end
