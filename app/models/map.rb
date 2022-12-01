# == Schema Information
#
# Table name: maps
#
#  id                :uuid             not null, primary key
#  default_latitude  :float
#  default_longitude :float
#  default_zoom      :float
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Map < ApplicationRecord
  # Relations
  has_many :access_groups, dependent: :destroy, inverse_of: :map
  has_many :layers, dependent: :destroy

  # Through relations
  has_many :users, through: :access_groups, inverse_of: :maps
  has_many :rows, through: :layers, inverse_of: :map

  # Query as scopes
  scope :with_last_updated_row_id, -> do
    joins(:rows)
      .order("maps.id, rows.updated_at DESC")
      .select("DISTINCT ON (maps.id) maps.*, rows.id as computed_last_updated_row_id")
  end
  belongs_to :last_updated_row, class_name: "Row", optional: true, foreign_key: "computed_last_updated_row_id" # rubocop:disable Rails/InverseOf

  # Hooks
  after_update_commit do
    if name_previously_changed?
      broadcast_i18n_replace_to self, target: dom_id(self, :name), partial: "maps/name"
    end
  end
end
