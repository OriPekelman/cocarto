module ImportExport
  class ExporterBase
    attr_reader :layer, :rows

    def initialize(layer, with_ids: false)
      @layer = layer
      @rows = @layer.rows_with_fields_values
      @with_ids = with_ids
    end

    def export
      Rails.cache.fetch([@layer, ImportExport::EXPORTERS.key(self.class)]) { export_rows }
    end

    def export_rows = raise NotImplementedError

    # Subclass helpers
    def exported_row_ids(row)
      @with_ids ? {id: row.id, feature_id: row.feature_id, author_id: row.author_id} : {}
    end

    def exported_row_geometry(row)
      # TODO: for territory layers, we may also include the geojson of the row.territory
      return {} if @layer.geometry_territory?

      # TODO: we may use wkt, or lat/long columns for points
      {geojson: row.geojson}
    end

    def exported_row_territory(row)
      return {} unless @layer.geometry_territory?

      {territory: row.territory.code}
    end

    def exported_row_statistics(row)
      row.calculated_properties

      # TODO: configure
    end

    def exported_row_field_values(row)
      row.fields_values.map do |field, value|
        if field.type_territory?
          value = exported_territory_value(value)
        elsif field.type_files?
          value = exported_files_value(value)
        end
        [field.label, value] # label is configurable
      end.to_h
    end

    def exported_territory_value(territory)
      territory&.code
    end

    def exported_files_value(attachments)
      attachments.map { |attachment| attachment.blob.filename.to_s }.join(",") # TODO: configure contents and array separator
    end
  end
end
