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

  ##
  def fields_columns
    super.presence || default_fields_columns
  end

  # Naive column mapping, field label => field id.
  def default_fields_columns
    layer.fields.to_h do |field|
      [field.label, field.id]
    end
  end

  private

  def layer_belongs_to_configuration_map
    errors.add(:layer, :invalid) unless layer.map_id == configuration.map_id
  end

  def reimport_field_belongs_to_layer
    return if reimport_field.nil?

    errors.add(:reimport_field, :invalid) unless reimport_field.layer_id == layer_id
  end
end
