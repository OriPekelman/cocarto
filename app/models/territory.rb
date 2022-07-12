# == Schema Information
#
# Table name: territories
#
#  id                    :uuid             not null, primary key
#  code                  :string
#  geometry              :geometry         multipolygon, 4326
#  name                  :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  parent_id             :uuid
#  territory_category_id :uuid             not null
#
# Indexes
#
#  index_territories_on_code_and_territory_category_id  (code,territory_category_id) UNIQUE
#  index_territories_on_name                            (name) USING gin
#  index_territories_on_parent_id                       (parent_id)
#  index_territories_on_territory_category_id           (territory_category_id)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => territories.id)
#  fk_rails_...  (territory_category_id => territory_categories.id)
#
class Territory < ApplicationRecord
  belongs_to :territory_category
  belongs_to :parent, class_name: "Territory"
  has_many :rows, dependent: :restrict_with_error

  # We use postgis functions to convert to geojson
  # This makes the load be on postgres’ side, not rails (C implementation)
  # We also compute the bounding box
  scope :with_geojson, -> do
    select(<<-SQL.squish
      name, id, parent_id, code, created_at, updated_at, territory_category_id,
      st_asgeojson(geometry) as geojson,
      st_Xmin(geometry) as lng_min,
      st_Ymin(geometry) as lat_min,
      st_Xmax(geometry) as lng_max,
      st_Ymax(geometry) as lat_max
    SQL
          )
  end

  scope :name_autocomplete, ->(name) {
    quoted_name = ActiveRecord::Base.connection.quote_string(name)
    where("name % :name", name: name)
      .order(Arel.sql("similarity(name, '#{quoted_name}') DESC"))
  }

  def to_s
    if id
      "#{name} (#{code})"
    else
      name
    end
  end
end
