class TerritoryCategoriesController < ApplicationController
  def index
    @categories = TerritoryCategory.all
  end

  def show
    @category = TerritoryCategory.find(params[:id])
  end
end
