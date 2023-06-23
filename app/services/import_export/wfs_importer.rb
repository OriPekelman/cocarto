require "open3"

module ImportExport
  class WfsImporter < ImporterBase
    # Additional @options:
    # - input_layer_name (string)
    def initialize(*args, **options)
      @input_layer_name = options.delete(:input_layer_name)
      super
    end

    def import_rows
      convert_to_geojson
      import_geojson
    end

    def convert_to_geojson
      # /vsistdout/ is  a special file to output to stdout https://gdal.org/user/virtual_file_systems.html#vsistdout-standard-output-streaming
      # 'EPSG:4326' -t_srs makes sure that everything is reprojected to 4326 (usual GPS coordinates)
      stdout, stderr, status = Open3.capture3("ogr2ogr", "-f", "geojson", "-t_srs", "EPSG:4326", "/vsistdout/", "WFS:#{@input}", @input_layer_name)
      if status.success?
        @input = stdout
      else
        raise ImportGlobalError, stderr
      end
    end

    def import_geojson
      geojson = RGeo::GeoJSON.decode(@input, geo_factory: RGEO_FACTORY)
      geojson.each_with_index do |feature, index|
        import_row(feature.geometry, feature.properties, index)
      end
    rescue JSON::ParserError
      raise ImportGlobalError
    end
  end
end
