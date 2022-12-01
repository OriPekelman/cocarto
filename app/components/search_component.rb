# frozen_string_literal: true

class SearchComponent < ViewComponent::Base
  def initialize(field:, territory:, form:, layer_id:, field_id:)
    @field = field
    @territory = territory
    @form = form
    @layer_id = layer_id
    @field_id = field_id
  end

  private

  def path
    search_territories_path(layer_id: @layer_id, field_id: @field_id)
  end

  def actions
    token_list("autocomplete:selected->row#save", "autocomplete:selected->new-territory#selected", "autocomplete:selected->dropdown#deactivate", "autocomplete:input->dropdown#activate")
  end
end
