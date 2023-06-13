# == Schema Information
#
# Table name: access_groups
#
#  id         :uuid             not null, primary key
#  name       :text
#  role_type  :enum             not null
#  token      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  map_id     :uuid             not null
#
# Indexes
#
#  index_access_groups_on_map_id  (map_id)
#  index_access_groups_on_token   (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (map_id => maps.id)
#
class AccessGroup < ApplicationRecord
  enum :role_type, {owner: "owner", editor: "editor", contributor: "contributor", viewer: "viewer"}

  # Relationships
  has_and_belongs_to_many :users
  belongs_to :map
end
