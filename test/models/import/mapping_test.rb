# == Schema Information
#
# Table name: import_mappings
#
#  id                         :uuid             not null, primary key
#  bulk_mode                  :boolean          default(FALSE), not null
#  fields_columns             :jsonb
#  geometry_columns           :string           is an Array
#  geometry_encoding_format   :string
#  geometry_srid              :integer
#  ignore_empty_geometry_rows :boolean          default(TRUE), not null
#  source_layer_name          :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  configuration_id           :uuid             not null
#  layer_id                   :uuid             not null
#  reimport_field_id          :uuid
#
# Indexes
#
#  index_import_mappings_on_configuration_id   (configuration_id)
#  index_import_mappings_on_layer_id           (layer_id)
#  index_import_mappings_on_reimport_field_id  (reimport_field_id)
#
# Foreign Keys
#
#  fk_rails_...  (configuration_id => import_configurations.id)
#  fk_rails_...  (layer_id => layers.id)
#  fk_rails_...  (reimport_field_id => fields.id)
#
require "test_helper"

class Import::MappingTest < ActiveSupport::TestCase
  class Validation < self
    test "layer must be a layer of the configuration’s map" do
      mapping = Import::Mapping.new(configuration: import_configurations(:restaurants_csv), layer: layers(:restaurants))

      assert_predicate mapping, :valid?

      mapping = Import::Mapping.new(configuration: import_configurations(:restaurants_csv), layer: layers(:hiking_paths))

      assert_not mapping.valid?
      assert_equal({layer: [{error: :invalid}]}, mapping.errors.details)
    end

    test "reimport field must belong to the layer" do
      mapping = import_mappings(:restaurants_csv)
      mapping.reimport_field = fields(:restaurant_name)

      assert_predicate mapping, :valid?

      mapping.reimport_field = fields(:hiking_paths_name)

      assert_not mapping.valid?
      assert_equal({reimport_field: [{error: :invalid}]}, mapping.errors.details)
    end
  end

  class BestNameMatching < self
    test "best_source_layer_name" do
      mapping = Layer.new(name: "restaurants").import_mappings.new

      assert_equal "restaurants", mapping.best_source_layer_name(["no name", "restaurants", "other"])
      assert_equal "Restaus", mapping.best_source_layer_name(["no name", "Restaus", "other"])
      assert_equal "other", mapping.best_source_layer_name(["other"])
    end

    test "best_fields_columns" do
      mapping = layers(:restaurants).import_mappings.new

      assert_equal({"name" => fields(:restaurant_name).id, "date 1" => fields(:restaurant_date).id, "x" => nil}, mapping.best_fields_columns(["name", "date 1", "x"]))
    end
  end

  class Mapping < self
    test "import with mapping" do
      layers(:restaurants).rows.destroy_all

      import_mappings(:restaurants_csv)
        .update(fields_columns: {
          "Nom" => fields(:restaurant_name).id,
          "Convives" => fields(:restaurant_table_size).id
        })

      attachable = attachable_data "restaurants.csv", <<~CSV
        Nom,Convives,geojson
        L’Antipode,70,"{""type"":""Point"",""coordinates"":[2.37516,48.88661]}"
      CSV
      import_configurations(:restaurants_csv).operations.create(local_source_file: attachable).import!(users(:reclus))

      row = layers(:restaurants).rows.includes(*layers(:restaurants).fields_association_names).last

      assert_equal "L’Antipode", row.fields_values[fields(:restaurant_name)]
      assert_equal 70, row.fields_values[fields(:restaurant_table_size)]
    end
  end

  class Reimport < self
    test "reimport should only update the values" do
      layers(:restaurants).rows.destroy_all
      import_mappings(:restaurants_csv).update(reimport_field: fields(:restaurant_name))

      attachable = attachable_fixture("restaurants.csv")
      import_configurations(:restaurants_csv).operations.create(local_source_file: attachable).import!(users(:reclus))
      bastringue = layers(:restaurants).rows.reload.last

      assert_equal 5, bastringue.fields_values[fields(:restaurant_rating)]

      attachable = attachable_data "restaurants.csv", <<~CSV
        Name,Rating
        Le Bastringue,10
      CSV
      import_configurations(:restaurants_csv).operations.create(local_source_file: attachable).import!(users(:reclus))

      assert_equal 2, layers(:restaurants).rows.count
      assert_equal 10, bastringue.reload.fields_values[fields(:restaurant_rating)]
    end
  end

  class BulkMode < self
    test "bulk mode should bulk import" do
      layers(:restaurants).rows.destroy_all
      import_mappings(:restaurants_csv).update(bulk_mode: true)

      attachable = attachable_fixture("restaurants.csv")
      import_configurations(:restaurants_csv).operations.create(local_source_file: attachable).import!(users(:reclus))
      bastringue = layers(:restaurants).rows.reload.last

      assert_equal 2, layers(:restaurants).rows.reload.count
      assert_equal "Le Bastringue", bastringue.fields_values[fields(:restaurant_name)]
      assert_equal 5, bastringue.fields_values[fields(:restaurant_rating)]
    end

    test "bulk mode should fail orderly" do
      layers(:restaurants).rows.destroy_all
      import_mappings(:restaurants_csv).update(bulk_mode: true)

      attachable = attachable_data "restaurants.csv", <<~CSV
        Name,Table,geometry
        L’Antipode,70,""
      CSV
      operation = import_configurations(:restaurants_csv).operations.create(local_source_file: attachable).import!(users(:reclus))

      assert_not operation.success?
      assert_includes operation.global_error, "PG::CheckViolation: ERROR:  new row for relation \"rows\" violates check constraint"
    end
  end
end
