module Importers
  class CSV < Base
    SUPPORTED_SOURCES = %i[local_source_file]
    def _source_configuration
      {
        source_csv_column_separator: col_sep,
        source_text_encoding: "UTF-8"
      }
    end

    def _source_layers = ["default"]

    def _source_columns(source_layer_name)
      csv = ::CSV.new(@source, headers: true, encoding: encoding, col_sep: col_sep)
      csv.rewind
      csv.first.to_h.transform_values { _1.class }
    rescue ::CSV::MalformedCSVError
      raise ImportGlobalError
    end

    def _source_geometry_analysis(source_layer_name, columns: nil, format: nil)
      csv = ::CSV.new(@source, headers: true, encoding: encoding, col_sep: col_sep)
      csv.rewind
      GeometryParsing.analyse_geometry(csv.first)
    rescue ::CSV::MalformedCSVError
      raise ImportGlobalError
    end

    def _import_rows
      csv = ::CSV.new(@source, headers: true, encoding: encoding, col_sep: col_sep)
      csv.rewind

      csv.each_with_index do |line, index|
        values = line.to_h
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
    rescue ::CSV::MalformedCSVError
      raise ImportGlobalError
    end

    def encoding
      @configuration.source_text_encoding.presence || "UTF-8" # We may want to use rchardet at some point; this seems overcomplicated for now.
    end

    def col_sep
      @configuration.source_csv_column_separator.presence || autodetect_col_sep
    end

    private

    def autodetect_col_sep # Find a separator that gives the same number of columns for all rows
      separators = %W[, ; \t]
      separator = separators.find do |sep|
        rows = ::CSV.new(@source, col_sep: sep).first(100)
        row_lengths = rows.map(&:length)
        row_lengths.uniq.size == 1 # all rows have the same column count
      rescue ::CSV::MalformedCSVError
        false
      ensure
        @source.rewind if @source.is_a? IO
      end
      # fallback to ","
      separator || ","
    end
  end
end
