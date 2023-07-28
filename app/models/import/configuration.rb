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
  enum :source_type, {random: "random", csv: "csv", geojson: "geojson", wfs: "wfs"}

  # Relations
  belongs_to :map
  has_many :mappings, class_name: "Import::Mapping", dependent: :destroy
  has_many :operations, class_name: "Import::Operation", dependent: :destroy

  accepts_nested_attributes_for :mappings

  # Validations
  validates :source_type, presence: true

  IMPORTERS = {
    random: Importers::Random,
    csv: Importers::CSV,
    geojson: Importers::GeoJSON,
    wfs: Importers::WFS,
    spreadsheet: Importers::Spreadsheet
  }

  def importer_class
    IMPORTERS[source_type&.to_sym]
  end

  def importer(source, author)
    importer_class.new(self, source, author, stream: true)
  end
end
