module ImportExport
  class GeojsonImporter < ImporterBase
    def import_rows
      geojson = RGeo::GeoJSON.decode(@input, geo_factory: RGeo::Cartesian.factory(srid: 4326))
      geojson.each do |feature|
        values = feature.properties
        geometry = if feature.geometry.geometry_type.type_name.start_with?("Multi")
          if feature.geometry.size > 1
            Rails.logger.debug "Feature has more than one element, skipping the others"
          end
          feature.geometry[0]
        else
          feature.geometry
        end

        import_row(geometry, values)
      end
    end
  end
end
