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
      if columns.present? && format.present?
        begin
          geometry = extract_geometry(values, columns, format)
          if geometry
            return GeometryAnalysis.new(columns: columns, format: format, type: geometry.geometry_type.type_name, geometry: geometry)
          end
        rescue ImportGeometryError
          # Ignore error when analysing
        end
      else
        STRATEGIES.each do |strategy|
          # Look for different-casing keys
          existing_columns = strategy[:columns].map { |col| values.to_h.keys.find { |k| k.casecmp(col) == 0 } || col }

          geometry = extract_geometry(values, existing_columns, strategy[:format])
          if geometry
            return GeometryAnalysis.new(
              columns: existing_columns,
              format: strategy[:format],
              type: geometry.geometry_type.type_name,
              geometry: geometry
            )
          end
        rescue ImportGeometryError
          # Ignore error when analysing
        end
      end

      GeometryAnalysis.new
    end
  end
end
