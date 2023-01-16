# frozen_string_literal: true

class ColumnStatsComponent < ViewComponent::Base
  def initialize(layer:)
    @layer = layer
  end

  private

  def calculated_columns
    case @layer.geometry_type
    when "territory"
      tag.td(nil, class: "calculated") + tag.td(nil, class: "calculated")
    when "point"
      tag.td(nil, class: "calculated") + tag.td(nil, class: "calculated")
    when "line_string"
      sum = number_to_human(@layer.rows.sum(:geo_length), units: :length)
      tag.td(sum, class: "layer-table__td__numerical calculated")
    when "polygon"
      sum = number_to_human(@layer.rows.sum(:geo_area), units: :area)
      tag.td(sum, class: "layer-table__td__numerical calculated")
    end
  end
end
