# frozen_string_literal: true

class FileFieldComponent < ViewComponent::Base
  def initialize(row:, field:)
    @row = row
    @field = field
  end

  def files
    @row.fields_values[@field] || []
  end

  def field_name
    "row[fields_values][#{@field.id}][]"
  end
end
