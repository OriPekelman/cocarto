# frozen_string_literal: true

class RowComponent < ViewComponent::Base
  def initialize(row:, extra_class: "")
    @row = row
    @extra_class = extra_class
  end

  private

  def classes
    class_names("row", "layer-table__tr", @extra_class)
  end

  def form_id
    dom_id(@row, :inline_form)
  end

  def calculated_columns
    case @row.layer.geometry_type
    when "territory"
      tag.td(render(SearchComponent.new(form: form_id, field: "row[territory_id]", territory: @row.territory, field_id: nil, layer_id: @row.layer_id)),
        class: "layer-table__td layer-table__td--field layer-table__td--text") +
        tag.td(@row.territory.code, class: "layer-table__td layer-table__td--stats")
    when "point"
      tag.td(number_with_precision(@row.geo_lng_min, precision: 6), class: "layer-table__td layer-table__td--stats") +
        tag.td(number_with_precision(@row.geo_lat_min, precision: 6), class: "layer-table__td layer-table__td--stats")
    when "line_string"
      tag.td(number_to_human(@row.geo_length, units: :length), class: "layer-table__td layer-table__td--stats")
    when "polygon"
      tag.td(number_to_human(@row.geo_area, units: :area), class: "layer-table__td layer-table__td--stats")
    end
  end

  def row_tag_form
    form_with method: :patch, model: @row, id: form_id, data: {row_target: "form", action: "row#save"}, html: {hidden: true} do |form|
      form.button("save", hidden: true)
    end
  end
end
