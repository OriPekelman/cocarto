# frozen_string_literal: true

class FileFieldComponent < ViewComponent::Base
  def initialize(field:, row:)
    @field = field
    @row = row
  end

  def files
    @row.fields_values[@field] || []
  end

  def field_name
    "row[fields_values][#{@field.id}][]"
  end
end
