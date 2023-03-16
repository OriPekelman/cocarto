require "csv"

module ImportExport
  class Exporter
    def initialize(layer)
      @layer = layer
    end

    def csv
      CSV.generate do |csv|
        rows = @layer.rows.with_attached_files.includes(*@layer.fields_association_names)
        csv << exported_row(rows.first).keys
        rows.each do |row|
          csv << exported_row(row).values
        end
      end
    end

    def exported_row(row)
      exported_values = row.fields_values.map do |field, value|
        if field.type_territory?
          value = value&.code
        elsif field.type_files?
          value = value.map { |attachment| attachment.blob.filename.to_s }.join("\n")
        end
        [field.label, value]
      end.to_h

      exported_values.merge(geojson: row.geojson)
    end
  end
end
