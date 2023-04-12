# frozen_string_literal: true

class StatsFooterComponent < ViewComponent::Base
  def initialize(layer:)
    @layer = layer
  end

  private

  def calculated_columns
    case @layer.geometry_type
    when "territory"
      tag.td(nil) + tag.td(nil)
    when "point"
      tag.td(nil) + tag.td(nil)
    when "line_string"
      sum = number_to_human(@layer.rows.sum(:geo_length), units: :length)
      tag.td(sum, class: "layer-table__td--stats")
    when "polygon"
      sum = number_to_human(@layer.rows.sum(:geo_area), units: :area)
      tag.td(sum, class: "layer-table__td--stats")
    end
  end
end
