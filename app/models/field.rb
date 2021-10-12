class Field < ApplicationRecord
  belongs_to :layer
  enum enum_field_type: {text: :text, float: :float, integer: :integer}
  validates :field_type, inclusion: {in: enum_field_types.keys}
end
