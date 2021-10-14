class Point < ApplicationRecord
  belongs_to :layer
  after_create_commit -> { broadcast_append_to layer, target: "points-tbody"}
end
