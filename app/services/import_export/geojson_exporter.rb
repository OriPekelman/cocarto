module ImportExport
  class GeojsonExporter < ExporterBase
    def export_rows
      collection = RGeo::GeoJSON::FeatureCollection.new(rows.map { exported_row(_1) })
      RGeo::GeoJSON.encode(collection).to_json
    end

    def exported_row(row)
      feature = RGeo::GeoJSON.decode(exported_row_geometry(row)[:geojson])
      properties = exported_row_territory(row)
        .merge(exported_row_field_values(row))
        .merge(exported_row_statistics(row))

      identifiers = exported_row_ids(row)
      id = identifiers.delete(:id)
      properties.merge!(identifiers)

      RGeo::GeoJSON::Feature.new(feature, id, properties)
    end
  end
end
