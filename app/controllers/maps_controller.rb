class MapsController < ApplicationController
  before_action :set_map, only: %i[show destroy]

  def index
    @maps = current_user.maps.all
  end

  def show
    @map
  end

  def new
    @map = current_user.maps.new
  end

  def destroy
    @map.destroy
    redirect_to maps_url, notice: t("helpers.message.map.destroyed"), status: :see_other
  end

  def create
    map = current_user.maps.new(map_params)
    if map.save
      redirect_to map
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render "new", status: :unprocessable_entity
    end
  end

  private

  def set_map
    @map = authorize Map.find(params[:id])
  end

  def map_params
    params.require(:map).permit(:name)
  end
end
