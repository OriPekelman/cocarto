module ImportExport
  class GeojsonImporter < ImporterBase
    def import_rows
      geojson = RGeo::GeoJSON.decode(@input, geo_factory: RGeo::Cartesian.factory(srid: 4326))
      geojson.each do |feature|
        values = feature.properties.transform_keys do |k|
          @mapping[k] || k
        end

        row = if @key_field.present?
          @layer.rows.where("values->>? ilike ? ", @key_field, values[@key_field]).take
        end
        row = @layer.rows.new if row.nil?

        row.author = @author
        row.fields_values = values
        geometry = if feature.geometry.geometry_type.type_name.start_with?("Multi")
          if feature.geometry.size > 1
            Rails.logger.debug "Feature has more than one element, skipping the others"
          end
          feature.geometry[0]
        else
          feature.geometry
        end
        row.geometry = geometry # Set the geojson after new because the geometry setter requires the layer to be set, to know which actual column to use.
        row.save!
      end
    end
  end
end
