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
class Import::Configuration < ApplicationRecord
  # Attributes
  enum :source_type, {random: "random", csv: "csv", geojson: "geojson", wfs: "wfs", spreadsheet: "spreadsheet"}

  # Relations
  belongs_to :map
  has_many :mappings, class_name: "Import::Mapping", dependent: :destroy
  has_many :operations, class_name: "Import::Operation", dependent: :destroy

  accepts_nested_attributes_for :mappings, allow_destroy: true, reject_if: :all_blank # Note: :allow_destroy and :reject_if will be needed for multi-layer import configurations

  # Validations
  validates :source_type, presence: true

  ## Importers registry
  # The keys are used in the DB (for configuration.source_type) and the UI (for importer-specific i18n)
  # See also the #support method in each Importer class for capabilities.
  IMPORTERS = {
    random: Importers::Random,
    csv: Importers::CSV,
    geojson: Importers::GeoJSON,
    wfs: Importers::WFS,
    spreadsheet: Importers::Spreadsheet
  }

  # Return all the supported mime types. Used for the file input.
  def self.all_mimes
    IMPORTERS.flat_map { |_, klass| klass.support[:mimes] }.uniq.compact
  end

  # Importers that *may* be used to import this source.
  # - remove non-public importers
  # - select the relevant remote or local file importers (TODO: support fetching a remote file for a local importer)
  # - return only importers that support the passed content type
  # returns a list of possible values for configuration.source_type
  def self.possible_source_types(remote:, content_type: nil)
    possible_importers = IMPORTERS.filter do |_, klass|
      klass.support[:public] &&
        klass.support[:remote_only] == remote
    end

    if content_type.present?
      possible_importers = possible_importers.filter do |_, klass|
        klass.support[:mimes].include?(content_type)
      end
    end

    possible_importers.map(&:first)
  end

  # Actual importer class to use
  #  - source_type, in principle, is chosen from the possible_source_types
  def importer_class
    IMPORTERS[source_type&.to_sym]
  end

  # Instance of an importer for the source, ready to perform analysis and import
  #   - source is either open file or an URL, depending on the importer
  def importer(source, author, cache_key)
    importer_class.new(self, source, author, cache_key, stream: true)
  end

  ## Analysis
  #
  Analysis = Struct.new(
    :configuration, # Hash of Import::Configuration attributes
    :layers # Array of layer_names
  )
  def analysis(importer)
    Analysis.new(importer._source_configuration, importer._source_layers)
  end

  # Update using a source_analysis
  def configure_from_analysis(source_analysis)
    update(source_analysis.configuration)

    mappings.each do |mapping|
      mapping.source_layer_name ||= mapping.best_source_layer_name(source_analysis.layers)
      mapping.save
    end
  end
end
