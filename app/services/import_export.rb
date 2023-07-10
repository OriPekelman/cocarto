module ImportExport
  IMPORTERS = {
    random: RandomImporter,
    csv: CsvImporter,
    geojson: GeojsonImporter,
    wfs: WfsImporter
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

  # Naive column mapping, field name => field id.
  # Used as the :mapping option for import
  def self.default_field_mapping(layer)
    layer.fields.to_h do |field|
      [field.label, field.id]
    end
  end
end
