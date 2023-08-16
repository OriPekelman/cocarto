module Importers
  class Spreadsheet < Base
    SUPPORTED_SOURCES = %i[local_source_file]

    def _import_rows
      spreadsheet = Roo::Spreadsheet.open(@source)

      begin
        sheet = spreadsheet.sheet(@mapping.source_layer_name.presence || 0)
      rescue RangeError
        raise ImportGlobalError
      end

      sheet.parse(headers: :first_row).each_with_index do |line, index|
        values = line
        if @mapping.geometry_columns && @mapping.geometry_encoding_format
          begin
            geometry = GeometryParsing.extract_geometry(values, @mapping.geometry_columns, @mapping.geometry_encoding_format)
            import_row(geometry, values, index)
          rescue GeometryParsing::ImportGeometryError => e
            @report.add_entity_result(index, false, parsing_error: e.cause)
          end
        else
          geometry = GeometryParsing.guess_geometry(values)
          import_row(geometry, values, index)
        end
      end
    end
  end
end
