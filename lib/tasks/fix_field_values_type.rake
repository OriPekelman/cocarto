require_relative "../geojson_importer"
namespace :fix_data do
  desc "Casts all field values according to the actual field type"
  task fields_values_type: :environment do
    integers = ActiveRecord::Base.connection.update(query("integer", "integer"))
    puts "Updated #{integers} integers"
    floats = ActiveRecord::Base.connection.update(query("float", "float"))
    puts "Updated #{floats} floats"
    booleans = ActiveRecord::Base.connection.update(query("boolean", "bool"))
    puts "Updated #{booleans} booleans"
  end
end

def query(field_type, casted)
  <<-SQL.squish
  WITH filtered_fields AS (
    SELECT id::text, layer_id
    FROM fields
    WHERE field_type='#{field_type}'
  )
  UPDATE rows
    SET values = jsonb_set(values, ARRAY[filtered_fields.id], CASE WHEN values->>filtered_fields.id = '' THEN null ELSE to_jsonb((values->>filtered_fields.id)::#{casted}) END)
    FROM filtered_fields
    WHERE
      values->>filtered_fields.id IS NOT NULL
      AND jsonb_typeof(values->filtered_fields.id) = 'string'
  SQL
end
