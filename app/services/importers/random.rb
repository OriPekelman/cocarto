module Importers
  class Random < Base
    SUPPORTED_SOURCES = %i[local_source_file]

    def _import_rows
      # @source is a json string with keys:
      # row_count, long_min, long_max, lat_min, lat_max
      parameters = JSON.parse(@source.read)
      geometry_proc = -> { random_geometry(parameters["long_min"]..parameters["long_max"], parameters["lat_min"]..parameters["lat_max"]) }
      values_proc = proc { @mapping.layer.fields.to_h { [_1.id, random_value(_1)] } }

      parameters["row_count"].times do |index|
        geometry = geometry_proc.call.values.first
        values = values_proc.call

        import_row(geometry, values, index)
      end

      # TODO handle fast mode with insert_all!
    end

    private

    def random_geometry(long_range, lat_range)
      point_generator = proc { RGEO_FACTORY.point(rand(long_range), rand(lat_range)) }
      case @mapping.layer.geometry_type
      when "point"
        {point: point_generator.call}
      when "line_string"
        {line_string: RGEO_FACTORY.line_string(Array.new(4, &point_generator))}
      when "polygon"
        # 3 points only to prevent invalid geometries
        {polygon: RGEO_FACTORY.polygon(RGEO_FACTORY.linear_ring(Array.new(3, &point_generator)))}
      when "territory"
        {territory_id: Territory.all.sample.id}
      end
    end

    def random_value(field)
      case field.field_type
      when "text"
        SecureRandom.alphanumeric(10)
      when "float"
        rand(0.0..100.0)
      when "integer"
        rand(0..10)
      when "territory"
        Territory.joins(:territory_category).merge(field.territory_categories).sample.id
      when "date"
        rand(10.years.ago..10.years.from_now)
      when "boolean"
        [true, false].sample
      when "css_property"
        "##{SecureRandom.hex(3)}" # See #286
      when "enum"
        field.enum_values.sample
      when "files"
        nil
      end
    end
  end
end
