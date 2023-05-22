module ImportExport
  class GeojsonImporter < ImporterBase
    def import_rows
      geojson = RGeo::GeoJSON.decode(@input, geo_factory: RGEO_FACTORY)
      geojson.each do |feature|
        import_row(feature.geometry, feature.properties)
      end
    end
  end
end
