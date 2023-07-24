# == Schema Information
#
# Table name: import_reports
#
#  id           :uuid             not null, primary key
#  row_results  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  mapping_id   :uuid             not null
#  operation_id :uuid             not null
#
# Indexes
#
#  index_import_reports_on_mapping_id    (mapping_id)
#  index_import_reports_on_operation_id  (operation_id)
#
# Foreign Keys
#
#  fk_rails_...  (mapping_id => import_mappings.id)
#  fk_rails_...  (operation_id => import_operations.id)
#
require "test_helper"

class Import::ReportTest < ActiveSupport::TestCase
  test "no geometry (validation error)" do
    import_mappings(:restaurants_csv).update(ignore_empty_geometry_rows: false)

    data = <<~CSV
      Nom;Convives;geometry
      L’Antipode;70;""
    CSV

    operation = import_configurations(:restaurants_csv)
      .operations.create!(local_source_file: attachable_data("restaurants.csv", data))
      .import!(users(:reclus))

    assert_not operation.success?
    assert_equal({geometry: [{error: :required}]}, operation.reports[0].row_results[0].errors)
    assert_equal ["The geometry is required."], operation.reports[0].full_error_messages(0)
  end

  test "bad geometry (parsing Error)" do
    import_mappings(:restaurants_csv).update(geometry_columns: ["geometry"], geometry_encoding_format: :wkt)

    csv = attachable_data "restaurants.csv", <<~CSV
      Nom;Convives;geometry
      L’Antipode;70;"NOT A GEOMETRY"
    CSV
    operation = import_configurations(:restaurants_csv)
      .operations.create!(local_source_file: csv)
      .import!(users(:reclus))

    assert_not operation.success?
    assert_match(/Unknown type .*\(RGeo::Error::ParseError\)/, operation.reports[0].row_results[0].parsing_error) # On CI the message is a bit different, because we don’t use libgeos (!566)
  end
end
