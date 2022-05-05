require_relative "../geojson_importer"
namespace :import do
  desc "Imports a territory as geojson into the database"
  task :geojson, [:uri, :category, :revision] => :environment do |t, args|
    puts "importing #{args.uri}"
    GeojsonImporter.import(args.uri, args.category, args.revision)
  end
end
