class MapsController < ApplicationController
  before_action :authenticate_user!
  before_action :new_map, only: %i[new create]
  before_action :set_map, only: %i[show update destroy]

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @maps = policy_scope(Map)
  end

  def show
    @role_type = current_user.access_groups.find_by(map: @map)&.role_type
    respond_to do |format|
      format.html
      format.style { render json: @map.style(url_for(Layer)) }
    end
  end

  def new
  end

  def create
    if @map.update(map_params)
      redirect_to new_map_layer_url(@map)
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render "new", status: :unprocessable_entity
    end
  end

  def update
    if @map.update(map_params)
      if [:default_latitude, :default_longitude, :default_zoom].any? { _1.in? @map.previous_changes }
        flash.now[:notice] = t("helpers.message.map.center_and_zoom_saved")
      end
      respond_to do |format|
        format.turbo_stream { render turbo_stream: [turbo_stream.update("flash", partial: "layouts/flash")] }
        format.html { redirect_to layer_path(@map) }
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    @map.strict_loading!(false) # deletion in cascade to layers: :fields would trigger a violation
    @map.destroy
    redirect_to maps_url, notice: t("helpers.message.map.destroyed"), status: :see_other
  end

  private

  def set_map
    @map = Map.find(params[:id])
    authorize @map
  end

  def new_map
    @map = Map.new
    @map.access_groups.new(users: [current_user], role_type: :owner)
    authorize @map
  end

  def map_params
    params.require(:map).permit(:name, :default_latitude, :default_longitude, :default_zoom)
  end
end
