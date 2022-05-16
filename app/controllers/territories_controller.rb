class TerritoriesController < ApplicationController
  def show
    @territory = Territory.with_geojson.find(params[:id])
  end
end
