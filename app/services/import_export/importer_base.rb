require "csv"

module ImportExport
  class ImporterBase
    # @options:
    # - author
    # - stream: bool
    def initialize(layer, input, **options)
      @layer = layer
      @input = input
      @mapping = options[:mapping] || ImportExport.default_field_mapping(layer)
      @key_field = options[:key_field]
      @author = options[:author]
      @stream = options[:stream]
    end

    def import
      ApplicationRecord.transaction { import_rows }
    end

    # implemented by subclasses
    def import_rows = raise NotImplementedError

    # import a single row
    def import_row(geometry, values)
      # map keys
      values = values.transform_keys do |k|
        @mapping[k] || k
      end

      # find existing row to reimport
      row = if @key_field.present?
        @layer.rows.where("values->>? ilike ? ", @key_field, values[@key_field]).take
      end
      row = @layer.rows.new if row.nil?

      # assign values
      row.author = @author
      row.fields_values = values
      if geometry
        # Note: geometry may be nil when reimporting a row (from e.g. a data-only table).
        # Note: we set the geometry after the values because the geometry setter requires the layer to be known.
        row.geometry = geometry
      end

      row.save!
    end
  end
end
