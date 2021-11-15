class Point < ApplicationRecord
  belongs_to :layer
  after_create_commit -> { broadcast_append_to layer, target: "points-tbody" }
  after_destroy_commit -> { broadcast_remove_to layer }
  after_update_commit -> { broadcast_replace_to layer }
end
