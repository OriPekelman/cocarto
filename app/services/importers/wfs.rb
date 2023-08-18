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

    def source_info
      @source_info ||= begin
        stdout, stderr, status = Open3.capture3("ogrinfo", "-json", "WFS:#{@source}")
        if status.success?
          JSON.parse(stdout)
        else
          raise ImportGlobalError, stderr
        end
      end
    end

    def _source_layers
      source_info["layers"]&.pluck("name")
    end

    def _source_columns(source_layer_name)
      source_info["layers"].find { _1["name"] == source_layer_name }["fields"].pluck("name", "type").to_h
    end

    def _source_geometry_analysis(source_layer_name, columns: nil, format: nil)
      type = source_info["layers"].find { _1["name"] == source_layer_name }["geometryFields"].first["type"]
      GeometryParsing::GeometryAnalysis.new(type: type)
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
