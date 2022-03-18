class RowContent < ApplicationRecord
  belongs_to :layer
  after_update_commit -> { broadcast_replace_to layer }
  after_destroy_commit -> { broadcast_remove_to layer }
  after_create_commit -> { broadcast_append_to layer, target: "rows-tbody", partial: "row_contents/row_content", locals: {row_content: self} }
end
