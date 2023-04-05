class Import < Thor
  def self.exit_on_failure? = true

  desc "csv", "import csv"
  option :layer, required: true, type: :string, aliases: :l, desc: "The layer in which to insert rows", banner: "layer_id"
  option :file, required: true, type: :string, aliases: :f, desc: "CSV file"
  option :author, required: true, type: :string, aliases: :a, desc: "Row author", banner: "user_id"
  option :stream, required: false, type: :boolean, aliases: :s, desc: "Stream broadcast to frontend (slower)"
  def csv
    layer = Layer.find_by(id: options[:layer])
    author = User.find_by(id: options[:author])

    csv = File.read(options[:file])

    import = ImportExport::Importer.new(layer)
    import.csv(csv, author)
  end

  desc "random", "Insert new random rows in a layer"
  option :layer, required: false, type: :string, aliases: :l, desc: "The layer in which to insert rows", banner: "layer_id"
  option :count, required: false, type: :numeric, aliases: :c, desc: "How many new rows", default: 100
  option :author, required: false, type: :string, aliases: :a, desc: "Row author", banner: "user_id"
  option :lat_min, required: false, type: :numeric, desc: "min latitude", default: 42.3287 # France Métropolitaine
  option :lat_max, required: false, type: :numeric, desc: "max latitude", default: 51.0857
  option :long_min, required: false, type: :numeric, desc: "min longitude", default: -4.7955
  option :long_max, required: false, type: :numeric, desc: "max longitude", default: 8.2581
  option :stream, required: false, type: :boolean, aliases: :s, desc: "Stream broadcast to frontend (slower)"
  def random
    layer = Layer.find_by(id: options[:layer]) || Layer.all.sample
    row_count = options[:count]
    author = User.find_by(id: options[:author]) || User.joins(:access_groups).where(access_groups: layer.map.access_groups.find_by(role_type: %i[owner editor contributor])).sample

    puts "Adding #{row_count} #{Layer.human_attribute_name(layer.geometry_type, count: row_count)} to #{layer.id} (#{layer.map.name}:#{layer.name}) as #{author.id} (#{author.display_name})"

    import = ImportExport::Importer.new(layer, stream: options[:stream])
    import.create_random_rows(row_count, author, options[:lat_min]..options[:lat_max], options[:long_min]..options[:long_max])
  end
end