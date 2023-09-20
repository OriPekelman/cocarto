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
  enum :status, {ready: "ready", started: "started", fetching: "fetching", importing: "importing", done: "done"}
  serialize :global_error

  # Relations
  belongs_to :configuration, class_name: "Import::Configuration"
  has_many :reports, class_name: "Import::Report", dependent: :delete_all
  after_create_commit :configure_from_source # has to be before has_one_attached :local_source_file
  has_one_attached :local_source_file

  accepts_nested_attributes_for :configuration

  # Validations
  validate :either_local_file_remote_url
  validates :status, presence: true

  # Hooks
  before_validation :set_initial_source_type, on: :create
  after_update_commit -> { broadcast_i18n_replace_to configuration.map }

  def possible_source_types
    Import::Configuration.possible_source_types(remote: remote_source_url.present?)
  end

  def good_source_types
    Import::Configuration.possible_source_types(remote: remote_source_url.present?, content_type: local_source_file&.content_type)
  end

  # Analysis is made according to the current source and configuration.source_type
  # - may fail if the importer does not actually support the file (e.g. the content_type is misleading)
  # - returns a SourceAnalysis
  def analysis
    Rails.cache.fetch(["analysis", id, remote_source_url, local_source_file&.id]) do
      with_importer { |importer| configuration.analysis(importer) }
    end
  rescue Importers::ImportGlobalError => e
    errors.add(:base, (e.cause || e).detailed_message.force_encoding("utf-8"))
    Import::Configuration::Analysis.new({}, [])
  end

  # Analyse a specific source layer
  def layer_analysis(mapping)
    Rails.cache.fetch(["layer_analysis", id, remote_source_url, local_source_file&.id, mapping.source_layer_name]) do
      with_importer { |importer| mapping.analysis(importer) }
    end
  rescue Importers::ImportGlobalError => e
    errors.add(:base, (e.cause || e).detailed_message.force_encoding("utf-8"))
    Import::Mapping::Analysis.new({}, Importers::GeometryParsing::GeometryAnalysis.new)
  end

  def configure_from_source
    configuration.configure_from_analysis(analysis)
    configuration.mappings.each do |mapping|
      layer_analysis = layer_analysis(mapping)
      mapping.configure_from_analysis(layer_analysis)
      mapping.save
    end
  end

  def import(author)
    update!(status: :started)
    Job.perform_later(id, author)
  end

  class Job < ApplicationJob
    def perform(operation_id, author)
      operation = Import::Operation.includes(:reports, configuration: :map).with_attached_local_source_file.find(operation_id)
      operation.import!(author)
    end
  end

  def import!(author)
    with_importer(author) do |importer|
      import_source(importer)
    end

    self
  end

  def with_importer(author = nil)
    with_fetched_source do |source|
      yield(configuration.importer(source, author, id))
    end
  end

  def with_fetched_source(&block)
    if configuration.importer_class.support[:remote_only]
      raise ArgumentError if remote_source_url.blank?

      yield(remote_source_url)
    elsif local_source_file.present?
      local_source_file.open do |file|
        yield(file.open)
      end
    else
      # TODO: fetching a remote file for a local importer is not supported in the app yet, but it works for unit tests
      update(status: :fetching)
      io = URI.parse(remote_source_url).open
      yield(io)
    end
  end

  def import_source(importer)
    update(status: :importing)

    ApplicationRecord.transaction do
      configuration
        .mappings.includes(:reimport_field, layer: [:fields, :map])
        .map do |mapping|
        import_in_layer(importer, mapping)
      end
    rescue Importers::ImportGlobalError, ActiveRecord::ActiveRecordError => e
      self.global_error = (e.cause || e).detailed_message.force_encoding("utf-8")
    ensure
      raise ActiveRecord::Rollback unless success?
    end

    update(status: :done)
  end

  def import_in_layer(importer, mapping)
    report = reports.merge(mapping.reports).new
    importer.import_rows(report)
    report.save
  end

  def success?
    global_error.nil? && reports.all?(&:success?)
  end

  private

  def either_local_file_remote_url
    errors.add(:remote_source_url, :present) if local_source_file.present? && remote_source_url.present?
    errors.add(:remote_source_url, :blank) if local_source_file.blank? && remote_source_url.blank?
  end

  def set_initial_source_type
    if configuration.present? && configuration&.new_record? && configuration&.source_type.blank?
      configuration.source_type = good_source_types.first
    end
  end
end
