class RowContent < ApplicationRecord
  belongs_to :layer
  after_update_commit -> { broadcast_replace_to layer }
  after_destroy_commit -> { broadcast_remove_to layer }
  after_create_commit -> { broadcast_append_to layer, target: "rows-tbody", partial: "row_contents/row_content", locals: {row_content: self} }

  # Iterates of each field with its data
  def data
    layer.fields.each do |field|
      value = values[field.id]
      if field.field_type == "territory" && !value.nil?
        value = Territory.find(value)
      end
      yield [field, value]
    end
  end
end
