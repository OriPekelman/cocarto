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
  def importer(source, author)
    importer_class.new(self, source, author, stream: true)
  end

  ## Analysis
  #
  SourceAnalysis = Struct.new(
    :configuration, # Hash of Import::Configuration attributes
    :layers # Hash of source layer_name => SourceLayerAnalysis
  )

  SourceLayerAnalysis = Struct.new(
    :columns, # Hash of column name -> analysed data type
    :geometry # GeometryAnalysis
  )

  # Analyse the passed source using the importer for the current source_type
  # - may fail if the importer does not actually support the file (e.g. the content_type is misleading)
  # - returns a nested structure of SourceAnalysis / SourceLayerAnalysis / GeometryAnalysis
  def analysis(source)
    importer = importer(source, nil)

    source_configuration = importer._source_configuration
    layers_analyses = importer._source_layers.index_with do |layer_name|
      columns = importer._source_columns(layer_name)
      # If there’s already a mapping for this source layer, and that mapping has geometry attributes, use them.
      # (In that case we only use _source_geometry_analysis to find the geometry type)
      mapping = mappings.find_by(source_layer_name: layer_name)
      geometry_analysis = importer._source_geometry_analysis(layer_name, columns: mapping&.geometry_columns, format: mapping&.geometry_encoding_format)
      SourceLayerAnalysis.new(columns, geometry_analysis)
    end

    SourceAnalysis.new(source_configuration, layers_analyses)
  end

  # Update using a source_analysis
  def configure_from_analysis(source_analysis)
    update(source_analysis.configuration)

    mappings.each do |mapping|
      mapping.configure_from_analysis(source_analysis)
    end
  end
end
