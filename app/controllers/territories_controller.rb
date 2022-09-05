class TerritoriesController < ApplicationController
  def show
    @territory = authorize Territory.includes(:territory_category).with_geojson.find(search_params[:id])
  end

  def search
    territories = authorize Territory.includes(:territory_category).name_autocomplete(search_params[:q]).preload(:parent).limit(20)

    if search_params[:layer_id]
      cat = Layer.find(search_params[:layer_id]).territory_categories
      territories = territories.joins(:territory_category).merge(cat)
    end

    render turbo_stream: [
      turbo_stream.update(params[:result_id],
        partial: "territories/search_results",
        object: territories)
    ]
  end

  private

  def search_params
    params.permit(:q, :layer_id)
  end
end
