module Importers
  class GeoJSON < Base
    SUPPORTED_SOURCES = %i[local_source_file]

    def _import_rows
      geojson = RGeo::GeoJSON.decode(@source, geo_factory: RGEO_FACTORY)
      geojson.each_with_index do |feature, index|
        import_row(feature.geometry, feature.properties, index)
      end
    rescue JSON::ParserError
      raise ImportGlobalError
    end
  end
end
