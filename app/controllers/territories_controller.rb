class TerritoriesController < ApplicationController
  def show
    @territory = Territory.includes(:territory_category).with_geojson.find(params[:id])
  end

  def search
    territories = Territory.includes(:territory_category).name_autocomplete(params[:q]).preload(:parent).limit(20)
    render turbo_stream: [
      turbo_stream.update(params[:result_id],
        partial: "territories/search_results",
        object: territories)
    ]
  end
end
