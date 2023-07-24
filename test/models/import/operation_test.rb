# == Schema Information
#
# Table name: import_operations
#
#  id                :uuid             not null, primary key
#  global_error      :string
#  remote_source_url :string
#  status            :enum             default("ready"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  configuration_id  :uuid             not null
#
# Indexes
#
#  index_import_operations_on_configuration_id  (configuration_id)
#
# Foreign Keys
#
#  fk_rails_...  (configuration_id => import_configurations.id)
#
require "test_helper"

class Import::OperationTest < ActiveSupport::TestCase
  class Validation < Import::OperationTest
    test "neither local nor remote" do
      operation = Import::Operation.new(configuration: import_configurations(:restaurants_csv))

      assert_not operation.valid?
      assert_equal({remote_source_url: [{error: :blank}]}, operation.errors.details)
    end

    test "local and remote" do
      attachable = {io: file_fixture("restaurants.csv").open, filename: "restaurants", content_type: "text/csv"}
      operation = Import::Operation.new(configuration: import_configurations(:restaurants_csv), local_source_file: attachable, remote_source_url: "https://example.com/api")

      assert_not operation.valid?
      assert_equal({remote_source_url: [{error: :present}]}, operation.errors.details)
    end
  end

  class GlobalResult < Import::OperationTest
    test "unknown type error" do
      operation = import_configurations(:restaurants_geojson)
        .operations.create!(local_source_file: attachable_data("restaurants.txt", "some data"))
        .import!(users(:reclus))

      assert_not operation.success?
      assert_equal "unexpected token at 'some data' (JSON::ParserError)", operation.global_error
    end

    test "geojson parsing error" do
      operation = import_configurations(:restaurants_geojson)
        .operations.create!(local_source_file: attachable_data("restaurants.json", "Ceci n’est pas un geojson."))
        .import!(users(:reclus))

      assert_not operation.success?
      assert_equal "unexpected token at 'Ceci n’est pas un geojson.' (JSON::ParserError)", operation.global_error
    end

    test "csv parsing error" do
      operation = import_configurations(:restaurants_csv)
        .operations.create!(local_source_file: attachable_data("restaurants.csv", 'Ceci,""n’est, pas un csv.'))
        .import!(users(:reclus))

      assert_not operation.success?
      assert_equal "Any value after quoted field isn't allowed in line 1. (CSV::MalformedCSVError)", operation.global_error
    end

    test "success" do
      operation = import_configurations(:restaurants_csv)
        .operations.create!(local_source_file: attachable_fixture("restaurants.csv"))
        .import!(users(:reclus))

      assert_predicate operation, :success?
    end
  end

  class RemoteSourceToLocalFile < Import::OperationTest
    setup { start_fixtures_server }

    test "download a remote csv" do
      operation = import_configurations(:restaurants_csv)
        .operations.create!(remote_source_url: "#{fixtures_server_url}/restaurants.csv")
        .import!(users(:reclus))

      assert_predicate operation, :success?
    end
  end
end
