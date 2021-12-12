class RowContent < ApplicationRecord
  belongs_to :layer
  belongs_to :geometry, polymorphic: true
  after_update_commit -> { broadcast_replace_to layer }
  after_destroy_commit -> { broadcast_remove_to layer }
end
