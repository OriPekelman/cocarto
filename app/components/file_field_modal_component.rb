# frozen_string_literal: true

class FileFieldModalComponent < ViewComponent::Base
  def initialize(value:, field:, field_name:, opts:, row:)
    @value = value || []
    @field = field
    @field_name = field_name
    @opts = opts
    @row = row
  end

  def id = dom_id(@field, @opts[:form])

  def opts = @opts.merge(multiple: true)
end
