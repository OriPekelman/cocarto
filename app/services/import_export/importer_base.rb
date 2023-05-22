require "csv"

module ImportExport
  class ImportGlobalError < StandardError; end

  ## Result of the whole import operation
  # contains both a global status and results for each entity that was (or wasn't) imported.
  class ImportResult
    attr_accessor :global_error
    attr_reader :entity_results

    EntityResult = Struct.new(:did_save, :parsing_error, :validation_errors, :validation_warnings)

    def initialize
      @entity_results = []
    end

    def entity_result(index)
      @entity_results[index] ||= EntityResult.new
    end

    def success?
      global_error.nil? && @entity_results.all? { |entity_result| entity_result.did_save }
    end
  end

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
      @result = ImportResult.new
      ApplicationRecord.transaction do
        begin
          import_rows
        rescue ImportGlobalError => e
          @result.global_error = e.cause
        end

        raise ActiveRecord::Rollback unless @result.success?
      end

      @result
    end

    # implemented by subclasses
    def import_rows = raise NotImplementedError

    # import a single row
    # The index is used as context for the concrete subclass.
    # (the line number for CSV, the feature index for geojson…)
    def import_row(geometry, values, index)
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
      if geometry
        # Note: geometry may be nil when reimporting a row (from e.g. a data-only table).
        row.geometry = geometry
      end
      row.fields_values = values

      did_save = row.save

      set_entity_result(index, did_save: did_save, validation_errors: row.errors.presence, validation_warnings: row.warnings.presence)
    end

    # save the result for an index; this is called by import_row, but also by subclasses if needed
    def set_entity_result(index, did_save: nil, parsing_error: nil, validation_errors: nil, validation_warnings: nil)
      entity_result = @result.entity_result(index)
      entity_result.did_save = did_save
      entity_result.parsing_error = parsing_error
      entity_result.validation_errors = validation_errors
      entity_result.validation_warnings = validation_warnings
    end
  end
end
