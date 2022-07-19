class MapsController < ApplicationController
  before_action :new_map, only: %i[new create]
  before_action :set_map, only: %i[show destroy]

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @maps = policy_scope(Map)
  end

  def new
  end

  def create
    if @map.update(map_params)
      redirect_to @map
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render "new", status: :unprocessable_entity
    end
  end

  def show
    @map
  end

  def destroy
    @map.destroy
    redirect_to maps_url, notice: t("helpers.message.map.destroyed"), status: :see_other
  end

  private

  def set_map
    @map = Map.find(params[:id])
    authorize @map
  end

  def new_map
    @map = current_user.maps.new_owned
    authorize @map
  end

  def map_params
    params.require(:map).permit(:name)
  end
end
