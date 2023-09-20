module Importers
  class Spreadsheet < Base
    def self.support = {
      public: true,
      remote_only: false,
      multiple_layers: true,
      indeterminate_geometry: true,
      mimes: %w[
        application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
        application/vnd.oasis.opendocument.spreadsheet
        application/vnd.ms-excel
      ]
    }

    def _source_layers
      spreadsheet = Roo::Spreadsheet.open(@source)
      spreadsheet.sheets
    rescue ArgumentError
      raise ImportGlobalError
    end

    def _source_columns(source_layer_name)
      spreadsheet = Roo::Spreadsheet.open(@source)

      begin
        sheet = spreadsheet.sheet(source_layer_name)
        values = sheet.parse(headers: :first_row).first
        values&.transform_values { _1.class }
      rescue RangeError
        raise ImportGlobalError
      end
    end

    def _source_geometry_analysis(source_layer_name, columns: nil, format: nil)
      spreadsheet = Roo::Spreadsheet.open(@source)

      begin
        sheet = spreadsheet.sheet(source_layer_name)
        values = sheet.parse(headers: :first_row).first
        GeometryParsing.analyse_geometry(values) if values
      rescue RangeError
        raise ImportGlobalError
      end
    end

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
            @mapping.geometry_columns.each { values.delete(_1) } if geometry
            import_row(geometry, values, index)
          rescue GeometryParsing::ImportGeometryError => e
            @report.add_entity_result(index, false, parsing_error: e.cause)
          end
        else
          geometry = GeometryParsing.analyse_geometry(values).geometry
          import_row(geometry, values, index)
        end
      end
    end
  end
end
