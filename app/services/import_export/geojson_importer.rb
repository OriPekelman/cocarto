module ImportExport
  class GeojsonImporter < ImporterBase
    def import_rows
      geojson = RGeo::GeoJSON.decode(@input, geo_factory: RGEO_FACTORY)
      geojson.each_with_index do |feature, index|
        import_row(feature.geometry, feature.properties, index)
      end
    rescue JSON::ParserError
      raise ImportGlobalError
    end
  end
end
