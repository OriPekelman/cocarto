class Field < ApplicationRecord
  belongs_to :layer
  enum enum_field_type: {text: :text, float: :float, integer: :integer, territory: :territory}
  validates :field_type, inclusion: {in: enum_field_types.keys}

  after_create_commit -> do
    broadcast_append_to layer, target: "fields"
    broadcast_before_to layer, target: "delete-column", partial: "fields/th"
    layer.row_contents.each do |row_content|
      target = [row_content.id, "action"].join("-")
      broadcast_before_to layer, target: target, partial: "fields/field_in_form", locals: {field: self, form: row_content.id, value: nil}
    end
  end

  after_destroy_commit -> do
    broadcast_remove_to layer
    Turbo::StreamsChannel.broadcast_remove_to layer, targets: ".field-#{id}"
  end

  def numerical?
    ["float", "integer"].include?(field_type)
  end
end
