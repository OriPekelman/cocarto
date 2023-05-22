module ImportExport
  class CsvImporter < ImporterBase
    def import_rows
      csv = CSV.new(@input, headers: true)

      csv.each do |line|
        values = line.to_h
        geojson = values.delete("geojson")
        geometry = RGeo::GeoJSON.decode(geojson, geo_factory: RGEO_FACTORY)

        import_row(geometry, values)
      end
    end
  end
end
