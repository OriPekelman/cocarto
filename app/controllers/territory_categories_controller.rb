class TerritoryCategoriesController < ApplicationController
  def index
    @categories = TerritoryCategory.all
  end

  def show
    @category = TerritoryCategory.includes(:territories).find(params[:id])
    @territories = if params[:q]
      @category.territories.name_autocomplete(params[:q])
    else
      @category.territories
    end
  end
end
