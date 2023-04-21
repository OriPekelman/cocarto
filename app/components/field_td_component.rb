# frozen_string_literal: true

class FieldTdComponent < ViewComponent::Base
  def initialize(field:)
    @field = field
  end

  private

  def html_class_names
    type_specific_names = case @field.field_type
    when "text", "territory", "date", "css_property", "enum"
      %w[layer-table__td--field layer-table__td--text]
    when "float", "integer"
      %w[layer-table__td--field layer-table__td--numerical]
    when "boolean"
      %w[layer-table__td--checkbox]
    when "files"
      %w[layer-table__td--field layer-table__td--files]
    else
      raise ArgumentError
    end

    class_names("layer-table__td", "layer-table__td--editable",
      type_specific_names,
      dom_id(@field)) # used to mass-update a field css when a field is modified. See field#after_update_commit
  end
end
