class TerritoriesController < ApplicationController
  def show
    @territory = Territory.includes(:territory_category)..with_geojson.find(params[:id])
  end

  def search
    territories = Territory.includes(:territory_category).call(params[:q]).preload(:parent)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update(params[:result_id],
            partial: "territories/search_results",
            object: territories)
        ]
      end
    end
  end
end
