# == Schema Information
#
# Table name: territories
#
#  id                    :uuid             not null, primary key
#  code                  :string
#  geo_area              :decimal(, )
#  geo_lat_max           :decimal(, )
#  geo_lat_min           :decimal(, )
#  geo_lng_max           :decimal(, )
#  geo_lng_min           :decimal(, )
#  geojson               :text
#  geom_web_mercator     :geometry         geometry, 0
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
#  index_territories_on_geom_web_mercator               (geom_web_mercator) USING gist
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
  # Relations
  belongs_to :territory_category
  belongs_to :parent, class_name: "Territory", optional: true
  has_many :rows, dependent: :restrict_with_error

  scope :name_autocomplete, ->(name) {
    quoted_name = ActiveRecord::Base.connection.quote_string(name)
    where("territories.name % :name", name: name)
      .order(Arel.sql("similarity(territories.name, '#{quoted_name}') DESC"))
  }

  def to_s
    if code.present?
      "#{name} (#{code})"
    else
      name
    end
  end
end
