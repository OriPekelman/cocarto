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
class Import::Operation < ApplicationRecord
  # Attributes
  enum :status, {ready: "ready", fetching: "fetching", importing: "importing", done: "done"}
  serialize :global_error

  # Relations
  belongs_to :configuration, class_name: "Import::Configuration"
  has_many :reports, class_name: "Import::Report", dependent: :delete_all
  has_one_attached :local_source_file

  accepts_nested_attributes_for :configuration

  # Validations
  validate :either_local_file_remote_url
  validates :status, presence: true

  def success?
    global_error.nil? && reports.all?(&:success?)
  end

  private

  def either_local_file_remote_url
    errors.add(:remote_source_url, :present) if local_source_file.present? && remote_source_url.present?
    errors.add(:remote_source_url, :blank) if local_source_file.blank? && remote_source_url.blank?
  end
end
