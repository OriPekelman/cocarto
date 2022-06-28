class MapsController < ApplicationController
  before_action :set_map, only: %i[show]

  def index
    @maps = current_user.maps.all
  end

  def show
    @map
  end

  private

  def set_map
    @map = authorize Map.includes(:layers).find(params[:id])
  end
end
