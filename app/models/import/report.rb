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
class Import::Report < ApplicationRecord
  # Relations
  belongs_to :operation, class_name: "Import::Operation"
  belongs_to :mapping, class_name: "Import::Mapping"

  # Attributes
  serialize :row_results, Array # of RowResult
  RowResult = Struct.new(:did_save, # boolean
    :new_record, # boolean
    :ignored, # boolean
    :parsing_error, # String (from Exception#detailed_message)
    :errors,  # Hash (from ActiveModel::Errors#details)
    :warnings)   # Hash (from ActiveModel::Errors#details)

  def recreate_errors(details)
    errors_object = ActiveModel::Errors.new(mapping.layer.rows.new)
    details.each do |attribute, array|
      array.each do |detail|
        detail = detail.dup # the errors hash has an :error key, and other arbitrary keys.
        errors_object.add(attribute, detail.delete(:error), **detail)
      end
    end

    errors_object
  end

  def full_error_messages(index)
    recreate_errors(row_results[index].errors).full_messages
  end

  def full_warning_messages(index)
    recreate_errors(row_results[index].warnings).full_messages
  end

  # Validations
  validate :operation_and_mapping_have_the_same_configuration

  def success?
    row_results.all? { |row_result| row_result.did_save || row_result.ignored }
  end

  def saved_rows_count
    row_results.filter { _1.did_save }.size
  end

  def new_rows_count
    row_results.filter { _1.did_save && _1.new_record }.size
  end

  def updated_rows_count
    row_results.filter { _1.did_save && !_1.new_record }.size
  end

  def add_entity_result(index, did_save, new_record: false, parsing_error: nil, errors: nil, warnings: nil)
    result = RowResult.new(
      did_save: did_save,
      new_record: new_record,
      parsing_error: parsing_error&.detailed_message&.force_encoding("utf-8"),
      errors: errors&.details,
      warnings: warnings&.details
    )

    if mapping.ignore_empty_geometry_rows && !result.did_save && result.errors == {geometry: [{error: :required}]}
      result.ignored = true
    end
    row_results[index] = result
  end

  private

  def operation_and_mapping_have_the_same_configuration
    errors.add(:base, :invalid) if operation.configuration != mapping.configuration
  end
end
