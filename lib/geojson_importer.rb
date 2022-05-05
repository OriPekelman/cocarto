require "json"
require "rgeo/geo_json"
require "open-uri"

ACCEPTED_TYPE = ["Polygon", "MultiPolygon"]

module GeojsonImporter
  def self.import(uri, category, revision)
    file = if uri.starts_with?("http")
      URI.parse(uri).open.read
    else
      File.read(uri)
    end
    geojson = RGeo::GeoJSON.decode(file)
    puts "Reading #{uri} with #{geojson.size} features"

    factory = RGeo::Geos.factory(srid: 4326)
    ActiveRecord::Base.transaction do
      cat = TerritoryCategory.create(name: category, revision: revision)

      features = geojson.map do |feature|
        name = feature["nom"]
        code = feature["code"]
        geometry = feature.geometry

        # We store territories as multipolygon in Postgis
        # We must make them multi if they are simple
        if geometry.geometry_type == RGeo::Feature::Polygon
          geometry = factory.multi_polygon([geometry])
        elsif geometry.geometry_type != RGeo::Feature::MultiPolygon
          raise "Invalide geometry type #{geometry.type} for feature with name: #{name} and code: #{code}"
        end

        puts "  Processing geometry #{name} (#{code})"
        {name: name, geometry: geometry.as_text, territory_category_id: cat.id, code: code}
      end

      Territory.insert_all(features)
    end
  end
end
