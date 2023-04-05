module ImportExport
  IMPORTERS = {
    random: RandomImporter,
    csv: CsvImporter
  }

  # Import entry point
  def self.import(layer, format, input, **options)
    raise ArgumentError unless format.in? IMPORTERS.keys

    IMPORTERS[format].new(layer, input, **options).import
  end

  EXPORTERS = {
    geojson: GeojsonExporter,
    csv: CsvExporter
  }

  # Export entry point
  def self.export(layer, format)
    raise ArgumentError unless format.in? EXPORTERS.keys

    EXPORTERS[format].new(layer).export
  end
end
