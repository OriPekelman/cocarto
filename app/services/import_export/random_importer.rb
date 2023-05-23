module ImportExport
  class RandomImporter < ImporterBase
    # Additional @options:
    # row_count, lat_range, long_range
    def initialize(*args, **options)
      @row_count = options.delete(:row_count)
      @lat_range = options.delete(:lat_range)
      @long_range = options.delete(:long_range)
      super
    end

    def import_rows
      geometry_proc = -> { random_geometry }
      values_proc = proc { @layer.fields.to_h { [_1.id, random_value(_1)] } }

      entries = Array.new(@row_count) do
        {
          layer_id: @layer.id,
          author_id: @author.id,
          values: values_proc.call
        }.merge(geometry_proc.call)
      end

      if @stream
        Row.create!(entries)
      else
        Row.insert_all!(entries) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    private

    def random_geometry
      point_generator = proc { RGEO_FACTORY.point(rand(@long_range), rand(@lat_range)) }
      case @layer.geometry_type
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
