require "thor"

class Moulinette < Thor
  desc "rows", "yeah"
  option :layer, required: false, type: :string
  option :row_count, required: false, type: :numeric
  option :author, required: false, type: :string
  def rows
    layer = Layer.find_by(id: options.layer) || Layer.all.sample
    layer.strict_loading!(false)

    row_count = (options.row_count.present? ? options.row_count.to_i : 100)

    author = User.find_by(id: options.author) || User.joins(:access_groups).where(access_groups: layer.map.access_groups.find_by(role_type: %i[owner editor contributor])).sample

    # France Métropolitaine
    lat_range = 42.3287...51.0857
    long_range = -4.7955...8.2581

    puts "Adding #{row_count} #{Layer.human_attribute_name(layer.geometry_type, count: row_count)} to #{layer.id} (#{layer.map.name}:#{layer.name}) as #{author.id} (#{author.display_name})"

    geometry = case layer.geometry_type
    when "point"
      -> do
        {point: RGEO_FACTORY.point(rand(long_range), rand(lat_range))}
      end
    when "line_string"
      -> do
        {line_string: RGEO_FACTORY.line_string(Array.new(4) { RGEO_FACTORY.point(rand(long_range), rand(lat_range)) })}
      end
    when "polygon"
      -> do
        {polygon: RGEO_FACTORY.polygon(RGEO_FACTORY.linear_ring(Array.new(3) { RGEO_FACTORY.point(rand(long_range), rand(lat_range)) }))}
      end
    when "territory"
      -> do
        {territory_id: Territory.all.sample.id}
      end
    else
      raise "oh no"
    end

    entries = row_count.times.map do
      {
        layer_id: layer.id,
        author_id: author.id
      }.merge(geometry.call)
    end
    Row.insert_all!(entries) # rubocop:disable Rails/SkipsModelValidations
  end
end


