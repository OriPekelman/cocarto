require "thor"

class Moulinette < Thor
  desc "rows", "Insert new random rows in a layer"
  option :layer, required: false, type: :string, aliases: :l, desc: "The layer in which to insert rows", banner: "layer_id"
  option :count, required: false, type: :numeric, aliases: :c, desc: "How many new rows", default: 100
  option :author, required: false, type: :string, aliases: [:user, :a, :u], desc: "Row author", banner: "user_id"
  option :stream, required: false, type: :boolean, aliases: [:s], desc: "Stream broadcast to frontend (slower)"
  option :lat_min, required: false, type: :numeric, default: 42.3287 # France Métropolitaine
  option :lat_max, required: false, type: :numeric, default: 51.0857
  option :long_min, required: false, type: :numeric, default: -4.7955
  option :long_max, required: false, type: :numeric, default: 8.2581
  def rows
    layer = Layer.find_by(id: options[:layer]) || Layer.all.sample
    layer.strict_loading!(false)
    row_count = options[:count]
    author = User.find_by(id: options.author) || User.joins(:access_groups).where(access_groups: layer.map.access_groups.find_by(role_type: %i[owner editor contributor])).sample

    puts "Adding #{row_count} #{Layer.human_attribute_name(layer.geometry_type, count: row_count)} to #{layer.id} (#{layer.map.name}:#{layer.name}) as #{author.id} (#{author.display_name})"

    point_generator = proc { RGEO_FACTORY.point(rand(options[:long_min]..options[:long_max]), rand(options[:lat_min]..options[:lat_max])) }
    geometry_generator = case layer.geometry_type
    when "point"
      proc { {point: point_generator.call} }
    when "line_string"
      proc { {line_string: RGEO_FACTORY.line_string(Array.new(4, &point_generator))} }
    when "polygon"
      proc { {polygon: RGEO_FACTORY.polygon(RGEO_FACTORY.linear_ring(Array.new(3, &point_generator)))} }
    when "territory"
      proc { {territory_id: Territory.all.sample.id} }
    end

    entries = row_count.times.map do
      {
        layer_id: layer.id,
        author_id: author.id
      }.merge(geometry_generator.call)
    end
    if(options[:stream])
      Row.create!(entries)
    else
      Row.insert_all!(entries) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def self.exit_on_failure? = true
end
