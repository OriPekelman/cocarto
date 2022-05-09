class Territory < ApplicationRecord
  belongs_to :territory_category
  belongs_to :parent, class_name: "Territory"
end
