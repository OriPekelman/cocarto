module ImportExport
  EXPORTERS = {
    geojson: GeojsonExporter,
    csv: CSVExporter
  }

  # Export entry point
  def self.export(layer, format)
    raise ArgumentError unless format.in? EXPORTERS.keys

    EXPORTERS[format].new(layer).export
  end
end
