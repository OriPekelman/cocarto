module ImportExport
  class CsvImporter < ImporterBase
    def import_rows
      csv = CSV.new(@input, headers: true)

      csv.each do |line|
        values = line.to_h
        geojson = values.delete("geojson")
        values = values.transform_keys do |k|
          @mapping[k] || k
        end

        row = if @key_field.present?
          @layer.rows.where("values->>? ilike ? ", @key_field, values[@key_field]).take
        end
        row = @layer.rows.new if row.nil?

        row.author = @author
        row.fields_values = values
        row.geojson = geojson if geojson.present? # Set the geojson after new because the geometry setter requires the layer to be set, to know which actual column to use.
        row.save!
      end
    end
  end
end
