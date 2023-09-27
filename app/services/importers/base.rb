require "csv"

module Importers
  class ImportGlobalError < StandardError; end

  class Base
    def initialize(configuration, source, author, cache_key = nil, **options)
      @configuration = configuration
      @source = source
      @author = author
      @cache_key = cache_key
    end

    def self.support
      raise NotImplementedError
      # {
      #   public: bool,                  # appears in the UI selection
      #   remote_only: bool,             # a remote service (the source file can not be downloaded)
      #   multiple_layers: bool,         # source has multiple sheets (that can be imported at once to multiple layers)
      #   indeterminate_geometry: bool   # source data does not clearly encode geometry
      # }
    end

    ## Source Analysis (Implemented by subclasses)

    # returns guessed attributes for Import::Configuration
    def _source_configuration = {}

    # Source layer names
    def _source_layers = raise NotImplementedError

    # Column names of a specific source layer
    def _source_columns(source_layer_name) = raise NotImplementedError

    # The GeometryParsing::GeometryAnalysis of a specific source layer. We want to guess the format and columns if indeterminate, and we want the geometry type in any case.
    def _source_geometry_analysis(source_layer_name, columns: nil, format: nil) = raise NotImplementedError

    ## Layer import
    #
    def import_rows(report)
      @report = report
      @mapping = @report.mapping
      @layer = @mapping.layer
      @bulk_values = [] if @mapping.bulk_mode

      _import_rows

      insert_all_bulk_values if @mapping.bulk_mode
    end

    private

    # implemented by subclasses
    def _import_rows = raise NotImplementedError

    # import a single row
    # The index is used as context for the concrete subclass.
    # (the line number for CSV, the feature index for geojson…)
    def import_row(geometry, values, index)
      # map keys
      values = values.transform_keys do |k|
        @mapping.fields_columns[k] || k
      end

      if @mapping.bulk_mode
        add_bulk_values(geometry, values)
      else
        create_or_update_row(geometry, values, index)
      end
    end

    # slow mode
    def create_or_update_row(geometry, values, index)
      row = if @mapping.reimport_field.present?
        @layer.rows.find_by("values->>? ilike ? ", @mapping.reimport_field.id, values[@mapping.reimport_field.id])
      end
      row ||= @layer.rows.new

      row.author = @author
      row.fields_values = values
      row.geometry = geometry if geometry # Note: geometry may be nil when reimporting a row (from e.g. a data-only table).

      did_save = row.save

      @report.add_entity_result(index, did_save, new_record: row.id_previously_was.nil?, errors: row.errors, warnings: row.warnings)
    end

    # fast mode
    def add_bulk_values(geometry, values)
      # We don't go through the fields_values setter; filter and cast the values manually
      values = values.filter { _1.in? @layer.field_ids }
      values = values.map do |key, value|
        [key, @layer.fields.find(key).cast(value)]
      end.to_h

      @bulk_values << {
        @layer.geometry_type => geometry,
        :values => values,
        :author_id => @author.id
      }
    end

    def insert_all_bulk_values
      @layer.rows.insert_all(@bulk_values, returning: false) # rubocop:disable Rails/SkipsModelValidations

      @report.add_entity_result(0, true)
    rescue ActiveRecord::ActiveRecordError
      raise ImportGlobalError
    end
  end
end
