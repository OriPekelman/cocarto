require "open3"

module Importers
  class WFS < Base
    SUPPORTED_SOURCES = %i[remote_source_url local_source_file]

    def _import_rows
      geojson_str = convert_to_geojson
      import_geojson(geojson_str)
    end

    def convert_to_geojson
      # /vsistdout/ is  a special file to output to stdout https://gdal.org/user/virtual_file_systems.html#vsistdout-standard-output-streaming
      # 'EPSG:4326' -t_srs makes sure that everything is reprojected to 4326 (usual GPS coordinates)
      stdout, stderr, status = Open3.capture3("ogr2ogr", "-f", "geojson", "-t_srs", "EPSG:4326", "/vsistdout/", "WFS:#{@source}", @mapping.source_layer_name)
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
