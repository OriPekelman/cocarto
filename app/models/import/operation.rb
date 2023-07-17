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

  # Hooks
  after_update_commit -> { broadcast_i18n_replace_to configuration.map }

  def success?
    global_error.nil? && reports.all?(&:success?)
  end

  def import!(author)
    with_fetched_source do |source|
      import_source(source, author)
    end

    self
  end

  def with_fetched_source(&block)
    if local_source_file.present?
      raise ArgumentError if configuration.importer_class::SUPPORTED_SOURCES.exclude?(:local_source_file)

      local_source_file.open do |file|
        yield(file.open)
      end
    elsif configuration.importer_class::SUPPORTED_SOURCES.include?(:remote_source_url)
      yield(remote_source_url)
    else
      update(status: :fetching)
      io = URI.parse(remote_source_url).open
      yield(io)
    end
  end

  def import_source(source, author)
    update(status: :importing)

    ApplicationRecord.transaction do
      configuration
        .mappings.includes(:reimport_field, layer: [:fields, :map])
        .map do |mapping|
        import_in_layer(source, author, mapping)
      end
    rescue Importers::ImportGlobalError => e
      self.global_error = (e.cause || e).detailed_message.force_encoding("utf-8")
    ensure
      raise ActiveRecord::Rollback unless success?
    end

    update(status: :done)
  end

  def import_in_layer(source, author, mapping)
    report = reports.merge(mapping.reports).new
    configuration.importer(source, author).import_rows(report)
    report.save
  end

  private

  def either_local_file_remote_url
    errors.add(:remote_source_url, :present) if local_source_file.present? && remote_source_url.present?
    errors.add(:remote_source_url, :blank) if local_source_file.blank? && remote_source_url.blank?
  end
end
