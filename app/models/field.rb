class Field < ApplicationRecord
  belongs_to :layer
  enum enum_field_type: {text: :text, float: :float, integer: :integer}
  validates :field_type, inclusion: {in: enum_field_types.keys}

  after_create_commit -> do
    broadcast_append_to layer, target: "fields"
    broadcast_before_to layer, target: "delete-column", partial: "fields/th"
    Turbo::StreamsChannel.broadcast_before_to layer, targets: ".row-actions", inline: "<td class=\"field-#{id}\"></td>"
  end

  after_destroy_commit -> do
    broadcast_remove_to layer
    Turbo::StreamsChannel.broadcast_remove_to layer, targets: ".field-#{id}"
  end

  def geometry_type
    layer.geometry_type
  end

  def numerical?
    ["float", "integer"].include?(field_type)
  end
end
