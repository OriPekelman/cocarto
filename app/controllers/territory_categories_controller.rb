class TerritoryCategoriesController < ApplicationController
  def index
    @categories = TerritoryCategory.all.limit
  end

  def show
    @category = TerritoryCategory.find(params[:id])
  end
end
