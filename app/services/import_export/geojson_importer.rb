module ImportExport
  class GeojsonImporter < ImporterBase
    def import_rows
      geojson = RGeo::GeoJSON.decode(@input, geo_factory: RGeo::Cartesian.factory(srid: 4326))
      geojson.each do |feature|
        import_row(feature.geometry, feature.properties)
      end
    end
  end
end
