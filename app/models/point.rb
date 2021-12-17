class Point < ApplicationRecord
  belongs_to :layer
  has_one :row_content, as: :geometry
  after_create_commit -> { broadcast_append_to layer, target: "rows-tbody", partial: "row_contents/row_content", locals: {row_content: row_content} }
end
