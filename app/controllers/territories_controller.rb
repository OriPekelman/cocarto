class TerritoriesController < ApplicationController
  def show
    @territory = authorize Territory.includes(:territory_category).find(params[:id])
  end

  def search
    territories = authorize Territory.includes(:territory_category).name_autocomplete(search_params[:q]).preload(:parent).limit(20)

    cat = if search_params[:layer_id]
      Layer.find(search_params[:layer_id]).territory_categories
    else
      Field.find(search_params[:field_id]).territory_categories
    end
    territories = territories.joins(:territory_category).merge(cat)

    render partial: "territories/search_results", object: territories
  end

  private

  def search_params
    params.permit(:q, :layer_id, :field_id)
  end
end
