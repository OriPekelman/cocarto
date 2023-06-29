class CreateImportConfigurations < ActiveRecord::Migration[7.0]
  def change
    create_enum :import_source_type, %w[random csv geojson wfs]

    create_table :import_configurations, id: :uuid do |t|
      t.belongs_to :map, type: :uuid, null: false, foreign_key: true
      t.string :name
      t.enum :source_type, enum_type: :import_source_type, null: false
      t.string :remote_source_url
      t.string :source_text_encoding
      t.string :source_csv_column_separator

      t.timestamps
    end

    create_table :import_mappings, id: :uuid do |t|
      t.belongs_to :configuration, type: :uuid, null: false, foreign_key: {to_table: :import_configurations}
      t.belongs_to :layer, type: :uuid, null: false, foreign_key: true
      t.string :source_layer_name
      t.boolean :bulk_mode, null: false, default: false
      t.boolean :ignore_empty_geometry_rows, null: false, default: true
      t.string :geometry_encoding_format
      t.string :geometry_columns, null: true, array: true
      t.integer :geometry_srid
      t.jsonb :fields_columns
      t.belongs_to :reimport_field, type: :uuid, null: true, foreign_key: {to_table: :fields}

      t.timestamps
    end

    create_enum :import_operation_status, %w[ready fetching importing done]

    create_table :import_operations, id: :uuid do |t|
      t.belongs_to :configuration, type: :uuid, null: false, foreign_key: {to_table: :import_configurations}
      t.string :remote_source_url
      t.enum :status, enum_type: :import_operation_status, null: false, default: "ready"
      t.string :global_error

      t.timestamps
    end

    create_table :import_reports, id: :uuid do |t|
      t.belongs_to :operation, type: :uuid, null: false, foreign_key: {to_table: :import_operations}
      t.belongs_to :mapping, type: :uuid, null: false, foreign_key: {to_table: :import_mappings}

      t.string :row_results

      t.timestamps
    end
  end
end
