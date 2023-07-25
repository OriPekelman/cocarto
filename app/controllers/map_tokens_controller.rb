class MapTokensController < ApplicationController
  before_action :authenticate_user!
  before_action :set_map_token, only: %i[update destroy]

  def index
    @map_tokens = policy_scope(MapToken).where(map_id: params["map_id"])
    @map = Map.find(params["map_id"])

    @new_token = @map.map_tokens.new
  end

  def create
    map = Map.find(params["map_id"])
    map_token = authorize map.map_tokens.new(create_params)

    if map_token.save
      redirect_to map_map_tokens_path(map), notice: t("helpers.message.map_token.created")
    else
      redirect_to map_map_tokens_path(map), alert: t("common.failed", msg: map_token.errors.full_messages.to_sentence)
    end
  end

  def update
    @map = @map_token.map
    if @map_token.update(update_params)
      redirect_to map_map_tokens_path(@map), notice: t("helpers.message.map_token.updated")
    else
      redirect_to map_map_tokens_path(@map), alert: t("common.failed", msg: @map_token.errors.full_messages.to_sentence)
    end
  end

  def destroy
    @map = @map_token.map
    if @map_token.destroy
      redirect_to map_map_tokens_path(@map), alert: t("helpers.message.map_token.destroyed", status: :see_other)
    else
      redirect_to map_map_tokens_path(@map), alert: t("common.failed", msg: @map_token.errors.full_messages.to_sentence, status: :see_other)
    end
  end

  private

  def set_map_token
    @map_token = authorize MapToken.find(params[:id])
  end

  def create_params
    params.require(:map_token).permit(:role_type, :name)
  end

  def update_params
    params.require(:map_token).permit(:role_type, :name)
  end
end
