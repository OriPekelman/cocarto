class Export < Thor
  def self.exit_on_failure? = true

  desc "csv", "export csv"
  option :layer, required: false, type: :string, aliases: :l, desc: "The layer to export", banner: "layer_id"
  option :file, required: true, type: :string, aliases: :f, desc: "CSV file"
  def csv
    layer = Layer.find_by(id: options[:layer]) || Layer.all.sample

    exporter = ImportExport::Exporter.new(layer)
    File.write(options[:file], exporter.csv)
  end
end
