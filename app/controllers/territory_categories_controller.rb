class TerritoryCategoriesController < ApplicationController
  def index
    @categories = policy_scope(TerritoryCategory)
  end

  def show
    @category = authorize TerritoryCategory.includes(:territories).find(params[:id])
    @territories = if params[:q]
      @category.territories.name_autocomplete(params[:q])
    else
      @category.territories
    end
  end
end
