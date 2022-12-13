# frozen_string_literal: true

class RowComponent < ViewComponent::Base
  def initialize(row:, extra_class: "")
    @row = row
    @extra_class = extra_class
  end

  private

  def classes
    class_names("row", @extra_class)
  end

  def form_id
    dom_id(@row, :form)
  end

  def row_tag_calculated_data
    case @row.layer.geometry_type
    when "territory"
      tag.td(render(SearchComponent.new(form: form_id, field: "row[territory_id]", territory: @row.territory, field_id: nil, layer_id: row.layer_id), class: "calculated")) +
        tag.td(@row.territory.code, class: "calculated")
    when "point"
      tag.td(number_with_precision(@row.geo_lng_min, precision: 6), class: "numerical calculated") +
        tag.td(number_with_precision(@row.geo_lat_min, precision: 6), class: "numerical calculated")
    when "line_string"
      tag.td(number_to_human(@row.geo_length, units: :length), class: "numerical calculated")
    when "polygon"
      tag.td(number_to_human(@row.geo_area, units: :area), class: "numerical calculated")
    end
  end

  def row_tag_form
    form_with method: :patch, model: [@row.layer, @row], id: form_id, data: {row_target: "form", action: "row#save"} do |form|
      row_tag_geojson(form) +
        form.button("save", class: "is-hidden")
    end
  end

  def row_tag_geojson(form)
    # If our layer is a territory, we need the geojson for display
    # but we don’t want it in the from
    if !@row.layer.geometry_territory?
      form.hidden_field "geojson", data: {row_target: "geojson"}
    else
      hidden_field_tag "geojson", @row.territory.geojson, data: {row_target: "geojson"}
    end
  end
end
