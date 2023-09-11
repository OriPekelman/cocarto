require "csv"

module ImportExport
  class CSVExporter < ExporterBase
    def export_rows
      CSV.generate do |csv|
        csv << exported_row(rows.first).keys
        rows.each do |row|
          csv << exported_row(row).values
        end
      end
    end

    def exported_row(row)
      exported_row_ids(row)
        .merge(exported_row_geometry(row))
        .merge(exported_row_territory(row))
        .merge(exported_row_field_values(row))
        .merge(exported_row_statistics(row))
    end
  end
end
