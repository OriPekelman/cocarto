# == Schema Information
#
# Table name: territory_categories
#
#  id         :uuid             not null, primary key
#  name       :string
#  revision   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_territory_categories_on_name_and_revision  (name,revision) UNIQUE
#
class TerritoryCategory < ApplicationRecord
  # Relations
  has_many :territories, -> { limit(1000) }, dependent: :destroy, inverse_of: :territory_category
  has_and_belongs_to_many :layers
  has_and_belongs_to_many :fields

  def to_s
    if revision.present?
      "#{name} (#{revision})"
    else
      name
    end
  end
end
