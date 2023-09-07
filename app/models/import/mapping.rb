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
class Import::Mapping < ApplicationRecord
  # Relations
  belongs_to :configuration, class_name: "Import::Configuration"
  belongs_to :layer
  belongs_to :reimport_field, class_name: "Field", optional: true
  has_many :reports, class_name: "Import::Report", dependent: :delete_all

  # Validations
  validate :layer_belongs_to_configuration_map
  validate :reimport_field_belongs_to_layer
  validates :bulk_mode, inclusion: [true, false]
  validates :ignore_empty_geometry_rows, inclusion: [true, false]

  # Hooks
  before_update :reset_columns_when_layer_changes

  ## Analysis
  #
  Analysis = Struct.new(
    :columns, # Hash of column name -> analysed data type
    :geometry # GeometryAnalysis
  )

  def analysis(importer)
    columns = importer._source_columns(source_layer_name)
    geometry_analysis = importer._source_geometry_analysis(source_layer_name, columns: geometry_columns, format: geometry_encoding_format)
    Analysis.new(columns, geometry_analysis)
  end

  def configure_from_analysis(layer_analysis)
    self.fields_columns ||= best_fields_columns(layer_analysis.columns)
    self.geometry_columns ||= layer_analysis.geometry.columns
    self.geometry_encoding_format ||= layer_analysis.geometry.format
  end

  # Find the best source layer name matching the target layer; fallback to the first source layer.
  def best_source_layer_name(source_layer_names)
    checker = DidYouMean::SpellChecker.new(dictionary: source_layer_names)
    best_name = layer.name.in?(source_layer_names) ? layer.name : checker.correct(layer.name).first
    best_name || source_layer_names.first
  end

  # Find the best associations between source columns and target fields
  def best_fields_columns(source_columns)
    fields_by_label = layer.fields.index_by(&:label)
    checker = DidYouMean::SpellChecker.new(dictionary: fields_by_label.keys)

    result = source_columns.map do |name, _klass|
      best_name = name.in?(fields_by_label.keys) ? name : checker.correct(name).first
      [name, fields_by_label[best_name]&.id]
    end

    result.to_h
  end

  private

  def reset_columns_when_layer_changes
    return unless layer_id_changed? || (source_layer_name_changed? && !source_layer_name_was.nil?)

    self.fields_columns = nil
    self.geometry_columns = nil
    self.geometry_encoding_format = nil
  end

  def layer_belongs_to_configuration_map
    errors.add(:layer, :invalid) unless layer.map_id == configuration.map_id
  end

  def reimport_field_belongs_to_layer
    return if reimport_field.nil?

    errors.add(:reimport_field, :invalid) unless reimport_field.layer_id == layer_id
  end
end
