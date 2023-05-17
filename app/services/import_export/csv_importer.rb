module ImportExport
  class CsvImporter < ImporterBase
    # Additional @options:
    # encoding, col_sep
    def initialize(*args, **options)
      @encoding = options.delete(:encoding)
      @col_sep = options.delete(:col_sep)
      super
    end

    def import_rows
      csv = CSV.new(@input, headers: true, encoding: encoding, col_sep: col_sep)

      csv.each do |line|
        values = line.to_h
        geojson = values.delete("geojson")
        geometry = RGeo::GeoJSON.decode(geojson, geo_factory: RGEO_FACTORY)

        import_row(geometry, values)
      end
    end

    def encoding
      @encoding ||= "UTF-8" # We may want to use rchardet at some point; this seems overcomplicated for now.
    end

    def col_sep
      @col_sep ||= autodetect_col_sep
    end

    private

    def autodetect_col_sep # Find a separator that gives the same number of columns for all rows
      separators = %W[, ; \t]
      separator = separators.find do |sep|
        rows = CSV.new(@input, col_sep: sep).first(100)
        row_lengths = rows.map(&:length)
        row_lengths.uniq.size == 1 # all rows have the same column count
      rescue CSV::MalformedCSVError
        false
      ensure
        @input.rewind if @input.is_a? IO
      end
      raise InconsistentSeparator if separator.nil?

      separator
    end

    class InconsistentSeparator < StandardError
      def to_s
        I18n.t("import.errors.inconsistent_separator")
      end
    end
  end
end
