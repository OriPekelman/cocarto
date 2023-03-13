# frozen_string_literal: true

class FieldTdComponent < ViewComponent::Base
  def initialize(field:, value:, row:)
    @field = field
    @value = value
    @row = row
  end

  private

  def html_class
    class_names("layer-table__td", dom_id(@field),
      "layer-table__td--boolean" => @field.type_boolean?,
      "layer-table__td--numerical" => (@field.type_integer? || @field.type_float?))
  end
end
