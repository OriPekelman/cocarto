class TerritoriesController < ApplicationController
  def show
    @territory = Territory.with_geojson.find(params[:id])
  end

  def search
    territories = Territory.name_autocomplete(params[:q]).preload(:parent)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("search_results",
            partial: "territories/search_results",
            object: territories)
        ]
      end
    end
  end
end
