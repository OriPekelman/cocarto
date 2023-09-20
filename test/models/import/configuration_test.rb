# == Schema Information
#
# Table name: import_configurations
#
#  id                          :uuid             not null, primary key
#  name                        :string
#  remote_source_url           :string
#  source_csv_column_separator :string
#  source_text_encoding        :string
#  source_type                 :enum             not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  map_id                      :uuid             not null
#
# Indexes
#
#  index_import_configurations_on_map_id  (map_id)
#
# Foreign Keys
#
#  fk_rails_...  (map_id => maps.id)
#
require "test_helper"

class Import::ConfigurationTest < ActiveSupport::TestCase
  class ImportersRegistry < self
    test "all source_types map to an Importer class" do
      # In other frameworks or languages, this would be a compilation step.
      Import::Configuration.source_types.keys.each do |source_type|
        assert_not_nil Import::Configuration::IMPORTERS[source_type.to_sym]
      end
    end

    test "#possible_source_types" do
      assert_equal [:wfs], Import::Configuration.possible_source_types(remote: true, content_type: "application/xml")
      assert_equal [:csv], Import::Configuration.possible_source_types(remote: false, content_type: "text/csv")
      assert_equal [:csv, :geojson, :spreadsheet], Import::Configuration.possible_source_types(remote: false)
    end
  end

  class Validation < self
    test "source_type is unsupported" do
      # We need some gymnastics to properly format the error message.
      conf = Import::Configuration.create(map: maps(:restaurants), source_type: nil)

      assert_equal ["This source type is not supported."], conf.errors.full_messages

      # … especially when creating a configuration along with an operation
      op = Import::Operation.create(local_source_file: attachable_fixture("touladi.png"), configuration_attributes: {map: maps(:restaurants), source_type: nil})

      assert_equal({"configuration.source_type": [{error: :blank}]}, op.errors.details)
      assert_equal ["This source type is not supported."], op.errors.full_messages
    end
  end

  class Analysis < self
    test "#analysis" do
      layer = layers(:restaurants)
      config = layer.map.import_configurations.new(source_type: :csv, mappings: [layer.import_mappings.new])
      importer = config.importer(file_fixture("restaurants.csv").open, nil, nil)
      analysis = config.analysis(importer)

      assert_kind_of Hash, analysis.configuration
      assert_kind_of Array, analysis.layers
    end

    test "#configure_from_analysis" do
      analysis = Import::Configuration::Analysis.new(
        configuration: {source_csv_column_separator: "\t"},
        layers: ["restaurants"]
      )
      layer = layers(:restaurants)
      mapping = layer.import_mappings.new
      config = layer.map.import_configurations.new(source_type: :csv, mappings: [mapping])
      config.configure_from_analysis(analysis)

      assert_equal "\t", config.source_csv_column_separator
      assert_equal "restaurants", mapping.source_layer_name
    end
  end
end
