module RowHelper
  def row_tr(row, extra_class)
    data_attributes = {
      controller: "row",
      row_lng_min_value: row.geo_lng_min,
      row_lat_min_value: row.geo_lat_min,
      row_lng_max_value: row.geo_lng_max,
      row_lat_max_value: row.geo_lat_max,
      row_properties_value: row.css_properties,
      action: "focusin->map#highlightFeatures"
    }

    tag.tr id: dom_id(row), data: data_attributes, class: class_names("row", extra_class) do
      row_tag_calculated_data(row) +
        row_tag_data_cols(row) +
        row_tag_actions(row)
    end
  end

  private

  def row_tag_calculated_data(row)
    case row.layer.geometry_type
    when "territory"
      tag.td(render(SearchComponent.new(form: dom_id(row, :form), field: "row[territory_id]", territory: row.territory, field_id: nil, layer_id: row.layer_id), class: "calculated")) +
        tag.td(row.territory.code, class: "calculated")
    when "point"
      tag.td(number_with_precision(row.geo_lng_min, precision: 6), class: "numerical calculated") +
        tag.td(number_with_precision(row.geo_lat_min, precision: 6), class: "numerical calculated")
    when "line_string"
      tag.td(number_to_human(row.geo_length, units: :length), class: "numerical calculated")
    when "polygon"
      tag.td(number_to_human(row.geo_area, units: :area), class: "numerical calculated")
    end
  end

  def row_tag_data_cols(row)
    safe_join(row.fields_values.map { |field, value|
      render FieldTdComponent.new(field: field, value: value, form_id: dom_id(row, :form), author_id: row.author_id)
    })
  end

  def row_tag_actions(row)
    remove = button_to([row.layer, row], method: :delete, title: t("layers.layer.delete_row"), form: {data: {"turbo-confirm": t("common.confirm")}}) do
      embedded_svg("remove_item.svg", class: "icon--sm")
    end
    tag.td(id: dom_id(row, "actions"), class: "table-actions") do
      tag.div(class: "table-actions__container") do
        row_tag_form(row) +
          remove +
          button_tag(data: {action: "click->map#centerToRow"}, title: t("layers.layer.center_on_row")) do
            embedded_svg("center.svg", class: "icon--sm")
          end
      end
    end
  end

  def row_tag_form(row)
    form_with method: :patch, model: [row.layer, row], id: dom_id(row, :form), data: {row_target: "form", action: "row#save"} do |form|
      row_tag_geojson(row, form) +
        form.button("save", class: "is-hidden")
    end
  end

  def row_tag_geojson(row, form)
    # If our layer is a territory, we need the geojson for display
    # but we don’t want it in the from
    if !row.layer.geometry_territory?
      form.hidden_field "geojson", data: {row_target: "geojson"}
    else
      hidden_field_tag "geojson", row.territory.geojson, data: {row_target: "geojson"}
    end
  end
end
