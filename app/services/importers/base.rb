require "csv"

module Importers
  class ImportGlobalError < StandardError; end

  class Base
    def initialize(configuration, source, author, **options)
      @configuration = configuration
      @source = source
      @author = author
    end

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
        @layer.rows.where("values->>? ilike ? ", @mapping.reimport_field.id, values[@mapping.reimport_field.id]).take
      end
      row ||= @layer.rows.new

      row.author = @author
      row.fields_values = values
      row.geometry = geometry if geometry # Note: geometry may be nil when reimporting a row (from e.g. a data-only table).

      did_save = row.save

      @report.add_entity_result(index, did_save, errors: row.errors, warnings: row.warnings)
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
