task :moulinette, [:uri, :category, :revision, :parent, :parent_key] => :environment do |t, args|
  a_point_layer = Layer.includes(:map, :fields).geometry_point.sample
  author = User.all.sample
  count = 1000
  puts "adding #{count} points to #{a_point_layer.map.name}:#{a_point_layer.name} as #{author.display_name}"
  count.times do
    geojson = {coordinates: [rand(-3.0...8.0), rand(42.0...48.0)], type: "Point"}.to_json
    Row.create!(layer: a_point_layer, geojson: geojson, author:author)
  end
end
