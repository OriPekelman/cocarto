# frozen_string_literal: true

class FileComponent < ViewComponent::Base
  def initialize(value:, field_name:, row:)
    @value = value || []
    @field_name = field_name
    @row = row
  end
end
