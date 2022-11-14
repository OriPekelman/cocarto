require "json"
require "rgeo/geo_json"
require "open-uri"

ACCEPTED_TYPE = ["Polygon", "MultiPolygon"]

module GeojsonImporter
  def self.import(uri, category, revision, silent = false, parent = nil, parent_key = nil)
    file = if uri.starts_with?("http")
      URI.parse(uri).open.read
    else
      File.read(uri)
    end
    geojson = RGeo::GeoJSON.decode(file)
    Rails.logger.debug { "Reading #{uri} with #{geojson.size} features" } unless silent

    parent_category = find_parent_category!(parent, revision)
    parents_cache = {}

    factory = RGeo::Cartesian.factory(srid: 4326)
    ActiveRecord::Base.transaction do
      TerritoryCategory.upsert({name: category, revision: revision}, unique_by: %i[name revision]) # rubocop:disable Rails/SkipsModelValidations
      cat = TerritoryCategory.find_by!(name: category, revision: revision)

      features = geojson.map do |feature|
        name = feature["nom"]
        code = feature["code"]
        geometry = feature.geometry

        # We store territories as multipolygon in Postgis
        # We must make them multi if they are simple
        if geometry.geometry_type == RGeo::Feature::Polygon
          geometry = factory.multi_polygon([geometry])
        elsif geometry.geometry_type != RGeo::Feature::MultiPolygon
          raise "Invalid geometry type #{geometry.type} for feature with name: #{name} and code: #{code}"
        end

        Rails.logger.debug { "  Processing geometry #{name} (#{code})}" } unless silent
        parent_id = if parent
          parent_territory = parents_cache[feature[parent_key]] || parent_category.territories.find_by(code: feature[parent_key])
          if parent_territory.nil?
            Rails.logger.debug { "  ⚠ warning: Could not find parent (#{feature[parent_key]}) for #{name} (#{code})" }
          else
            parent_territory.id
          end
        end

        {
          name: name,
          geometry: geometry.as_text,
          territory_category_id: cat.id,
          code: code,
          parent_id: parent_id
        }
      end

      Territory.upsert_all(features, unique_by: %i[code territory_category_id]) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end

# If we define a parent we try to find it and raise if not found
# Otherwise returns nil
def find_parent_category!(parent, revision)
  if parent
    parent_category = TerritoryCategory.find_by(name: parent, revision: revision)
    raise "Territory category #{parent} (revision #{revision}) not found" if parent_category.nil?
    parent_category
  end
end
