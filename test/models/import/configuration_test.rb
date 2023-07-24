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
  class Consistency < Import::ConfigurationTest
    test "all source_types map to an Importer class" do
      # In other frameworks or languages, this would be a compilation step.
      Import::Configuration.source_types.keys.each do |source_type|
        assert_not_nil Import::Configuration.new(source_type: source_type).importer_class
      end
    end
  end

  class Validation < Import::ConfigurationTest
    test "source_type is unsupported" do
      # We need some gymnastics to properly format the error message.
      conf = Import::Configuration.create(map: maps(:restaurants), source_type: nil)

      assert_equal ["This source type is not supported."], conf.errors.full_messages

      # … especially when creating a configuration along with an operation
      op = Import::Operation.create(remote_source_url: "some:url", configuration_attributes: {map: maps(:restaurants), source_type: nil})

      assert_equal({"configuration.source_type": [{error: :blank}]}, op.errors.details)
      assert_equal ["This source type is not supported."], op.errors.full_messages
    end
  end
end
