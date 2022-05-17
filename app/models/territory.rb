class Territory < ApplicationRecord
  belongs_to :territory_category
  belongs_to :parent, class_name: "Territory"

  # We use postgis functions to convert to geojson
  # This makes the load be on postgres’ side, not rails (C implementation)
  # We also compute the bounding box
  scope :with_geojson, -> do
    select(<<-SQL
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
end
