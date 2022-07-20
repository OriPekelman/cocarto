class RolesController < ApplicationController
  before_action :set_role, only: %i[update destroy]

  def index
    @map = current_user.maps.find(params["map_id"])
    @roles = @map.roles.includes(:user)
  end

  def create
    @map = current_user.maps.find(params["map_id"])
    @role = @map.roles.new(role_params)

    if @role.save
      redirect_to role_url(@role), notice: t("helpers.message.role.created")
    else
      redirect_to :index, error: "failed"
    end
  end

  def update
    @map = @role.map
    if @role.update(role_params)
      redirect_to role_url(@role), notice: t("helpers.message.role.updated")
    else
      redirect_to :index, error: "failed"
    end
  end

  def destroy
    @role.destroy

    redirect_to roles_url, notice: t("helpers.message.role.destroyed")
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:role_type, user_attributes: [:email])
  end
end
