class Import < Thor
  def self.exit_on_failure? = true

  desc "import", "Import a file to an existing layer"
  option :layer, required: true, type: :string, aliases: :l, desc: "The layer in which to insert rows", banner: "layer_id"
  option :file, required: true, type: :string, aliases: :f, desc: "Source file"
  option :format, type: :string, enum: %w[csv geojson], default: :csv, desc: "File format"
  option :author, required: true, type: :string, aliases: :a, desc: "Row author", banner: "user_id"
  option :key_field, required: false, type: :string, aliases: :k, desc: "Identifier column name"
  option :stream, required: false, type: :boolean, aliases: :s, desc: "Stream broadcast to frontend (slower)"
  option :csv_col_sep, required: false, type: :string, desc: "CSV column separator"
  option :csv_encoding, required: false, type: :string, desc: "CSV encoding"
  option :geometry_keys, required: false, type: :array, desc: "geometry keys"
  option :geometry_format, required: false, type: :string, desc: "geometry format, one of #{ImportExport::ImporterBase::Geometry::PARSERS.keys}"
  def import
    opts = options.dup
    layer = Layer.find_by(id: opts.delete(:layer))
    format = opts.delete(:format).to_sym
    input = File.read(opts.delete(:file))
    opts[:author] = User.find_by(id: options[:author])
    opts[:key_field] = layer.fields.find_by(label: options[:key_field]).id if options[:key_field]

    ImportExport.import(layer, format, input, **opts)
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
    author = User.find_by(id: options[:author]) || layer.map.user_roles.where(role_type: %i[owner editor contributor]).sample.user

    puts "Adding #{row_count} #{Layer.human_attribute_name(layer.geometry_type, count: row_count)} to #{layer.id} (#{layer.map.name}:#{layer.name}) as #{author.id} (#{author.display_name})"

    ImportExport.import(layer, :random, nil, author: author, stream: options[:stream], row_count: row_count, lat_range: options[:lat_min]..options[:lat_max], long_range: options[:long_min]..options[:long_max])
  end
end
