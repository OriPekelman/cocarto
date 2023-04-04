require "csv"

module ImportExport
  class Importer
    def initialize(layer, stream: false)
      @layer = layer
      @stream = stream
    end

    def csv(csv, author)
      lines = CSV.parse(csv, headers: true)

      lines.each do |line|
        values = line.to_h
        geojson = values.delete("geojson")
        values = values.transform_keys do |k|
          @layer.fields.find_by(label: k).id
        end
        row = @layer.rows.new(author: author)
        row.fields_values = values
        row.geojson = geojson # Set the geojson after new because the geometry setter requires the layer to be set, to know which actual column to use.
        row.save!
      end
    end

    def create_random_rows(row_count, author, lat_range, long_range)
      geometry_proc = -> { random_geometry(@layer.geometry_type, lat_range, long_range) }
      values_proc = proc { @layer.fields.to_h { [_1.id, random_value(_1)] } }

      entries = row_count.times.map do
        {
          layer_id: @layer.id,
          author_id: author.id,
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

    def random_geometry(geometry_type, lat_range, long_range)
      point_generator = proc { RGEO_FACTORY.point(rand(long_range), rand(lat_range)) }
      case geometry_type
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
