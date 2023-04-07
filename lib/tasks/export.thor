class Export < Thor
  def self.exit_on_failure? = true

  default_command :export

  desc "export", "export a layer"
  option :layer, required: true, type: :string, aliases: :l, desc: "The layer to export ", banner: "layer_id"
  option :format, required: true, type: :string, aliases: :f, desc: "Export format, one of #{ImportExport::EXPORTERS.keys}"
  option :path, required: false, type: :string, aliases: :p, desc: "output file"
  def export
    layer = Layer.find_by(id: options[:layer])
    format = options[:format].to_sym
    file = options[:file] || "#{layer.id}.#{options[:format]}"

    File.write(file, ImportExport.export(layer, format))

    puts "Exported to #{file}"
  end
end
