module Importers
  class GeoJSON < Base
    SUPPORTED_SOURCES = %i[local_source_file]
    def _source_layers = ["default"]

    def _source_columns(source_layer_name)
      geojson = RGeo::GeoJSON.decode(@source, geo_factory: RGEO_FACTORY)
      @source.rewind
      geojson.first.properties.transform_values { _1.class }
    rescue JSON::ParserError
      raise ImportGlobalError
    end

    def _source_geometry_analysis(source_layer_name, columns: nil, format: nil)
      geojson = RGeo::GeoJSON.decode(@source, geo_factory: RGEO_FACTORY)
      @source.rewind
      geometry = geojson.first.geometry
      GeometryParsing::GeometryAnalysis.new(geometry: geometry, type: geometry.geometry_type&.type_name)
    rescue JSON::ParserError
      raise ImportGlobalError
    end

    def _import_rows
      geojson = RGeo::GeoJSON.decode(@source, geo_factory: RGEO_FACTORY)
      geojson.each_with_index do |feature, index|
        import_row(feature.geometry, feature.properties, index)
      end
    rescue JSON::ParserError
      raise ImportGlobalError
    end
  end
end
