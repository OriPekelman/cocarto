module Importers
  module GeometryParsing
    class ImportGeometryError < StandardError; end

    module_function

    PARSERS = {
      geojson: ->(value) { RGeo::GeoJSON.decode(value, geo_factory: RGEO_FACTORY) },
      wkt: ->(value) { RGEO_FACTORY.parse_wkt(value) },
      wkb: ->(value) { RGEO_FACTORY.parse_wkb(value) },
      xy: ->(x, y) { RGEO_FACTORY.point(x.to_f, y.to_f) }
    }

    def extract_geometry(values, columns, format) # raises ImportGeometryError
      geometry_values = values.values_at(*columns).compact
      return if geometry_values.size != columns.size

      PARSERS[format.to_sym].call(*geometry_values)
    rescue JSON::ParserError, RGeo::Error::ParseError
      raise ImportGeometryError
    end

    STRATEGIES = [
      {columns: %w[geojson], format: :geojson},
      {columns: %w[wkt], format: :wkt},
      {columns: %w[wkb], format: :wkb},
      {columns: %w[geometry], format: :geojson},
      {columns: %w[geometry], format: :wkt},
      {columns: %w[geometry], format: :wkb},
      {columns: %w[geom], format: :geojson},
      {columns: %w[geom], format: :wkt},
      {columns: %w[geom], format: :wkb},
      {columns: %w[longitude latitude], format: :xy},
      {columns: %w[long lat], format: :xy},
      {columns: %w[lon lat], format: :xy},
      {columns: %w[lng lat], format: :xy},
      {columns: %w[xlong ylat], format: :xy},
      {columns: %w[x y], format: :xy}
    ]

    GeometryAnalysis = Struct.new(
      :columns,  # Columns where the geometry was found
      :format,   # Format of the columns
      :geometry, # Found geometry
      :type      # Found geometry type
    )

    # Find a working strategy to extract a geometry from the passed values
    # Returns the columns, format, type of geometry (and the found geometry)
    def analyse_geometry(values, columns: nil, format: nil)
      geometry = nil
      working_strategy = nil

      strategies = if columns.present? && format.present?
        [{columns: columns, format: format}]
      else
        STRATEGIES
      end

      strategies.each do |strategy|
        geometry = extract_geometry(values, strategy[:columns], strategy[:format])
        if geometry
          working_strategy = strategy
          break
        end
      rescue ImportGeometryError
        # Ignore error when analysing
      end

      GeometryAnalysis.new(
        columns: working_strategy&.fetch(:columns),
        format: working_strategy&.fetch(:format),
        type: geometry&.geometry_type&.type_name,
        geometry: geometry
      )
    end
  end
end
