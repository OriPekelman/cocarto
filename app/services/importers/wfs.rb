require "open3"

module Importers
  class WFS < Base
    def self.support = {
      public: true,
      remote_only: true,
      multiple_layers: true,
      indeterminate_geometry: false,
      mimes: %w[application/gml+xml application/xml text/xml]
    }

    def cached_tool_command(*command)
      Rails.cache.fetch(["wfs", @cache_key, command]) do
        Open3.capture3(*command)
      end
    end

    def _source_layers
      stdout, stderr, status = cached_tool_command("ogrinfo", "-q", "WFS:#{@source}")
      if status.success?
        scanner = StringScanner.new(stdout)

        result = []
        while scanner.scan_until(/(?<index>\d+): (?<feature_type>.*?)[ $]/)
          result << scanner.named_captures["feature_type"]
        end

        result
      else
        raise ImportGlobalError, stderr
      end
    end

    def _source_columns(source_layer_name)
      stdout, stderr, status = cached_tool_command("ogrinfo", "-so", "-nocount", "-noextent", "-nomd", "WFS:#{@source}", source_layer_name)
      if status.success?
        scanner = StringScanner.new(stdout)
        # Attributes are described as “<key>: <type>” pairs after the “Geometry Column = <column>” line
        scanner.scan_until(/^Geometry Column = (?<geometry_column>.*)$/)
        result = {}
        while scanner.scan_until(/^(?<attribute>.*?): (?<type>.*?)$/)
          result[scanner.named_captures["attribute"]] = scanner.named_captures["type"]
        end
        result
      else
        raise ImportGlobalError, stderr
      end
    end

    def _source_geometry_analysis(source_layer_name, columns: nil, format: nil)
      stdout, stderr, status = cached_tool_command("ogrinfo", "-so", "-nocount", "-noextent", "-nomd", "WFS:#{@source}", source_layer_name)
      if status.success?
        scanner = StringScanner.new(stdout)
        scanner.scan_until(/^Geometry: (?<geometry_type>.*)$/)
        geometry_type = scanner.named_captures["geometry_type"]
        scanner.scan_until(/^Geometry Column = (?<geometry_column>.*)$/)
        geometry_column = scanner.named_captures["geometry_column"]
        GeometryParsing::GeometryAnalysis.new(columns: [geometry_column], type: geometry_type)
      else
        raise ImportGlobalError, stderr
      end
    end

    def _import_rows
      geojson_str = convert_to_geojson
      import_geojson(geojson_str)
    end

    def convert_to_geojson
      # /vsistdout/ is  a special file to output to stdout https://gdal.org/user/virtual_file_systems.html#vsistdout-standard-output-streaming
      # 'EPSG:4326' -t_srs makes sure that everything is reprojected to 4326 (usual GPS coordinates)
      stdout, stderr, status = Open3.capture3("ogr2ogr", "-f", "geojson", "-t_srs", "EPSG:4326", "/vsistdout/", "WFS:#{@source}", @mapping.source_layer_name || "")
      if status.success?
        stdout
      else
        raise ImportGlobalError, stderr
      end
    end

    def import_geojson(geojson_str)
      geojson = RGeo::GeoJSON.decode(geojson_str, geo_factory: RGEO_FACTORY)
      geojson.each_with_index do |feature, index|
        import_row(feature.geometry, feature.properties, index)
      end
    rescue JSON::ParserError
      raise ImportGlobalError
    end
  end
end
