class RolesController < ApplicationController
  before_action :set_role, only: %i[update destroy]

  def index
    @map = current_user.maps.find(params["map_id"])
    @roles = authorize @map.roles.includes(:user)
  end

  def create
    @map = current_user.maps.find(params["map_id"])
    create_params = create_role_params
    if (existing_user = User.find_by(email: create_params.dig(:user_attributes, :email)))
      create_params.delete(:user_attributes)
      create_params[:user] = existing_user
    end

    @role = authorize @map.roles.new(create_params)

    if @role.save
      if @role.user.invitation_sent_at.blank?
        @role.user.invite!
      end
      redirect_to map_roles_path(@map), notice: t("helpers.message.role.created")
    else
      redirect_to map_roles_path(@map), alert: "failed: #{@role.errors.full_messages.to_sentence}"
    end
  end

  def update
    @map = @role.map
    if @role.update(update_role_params)
      redirect_to map_roles_path(@map), notice: t("helpers.message.role.updated")
    else
      redirect_to map_roles_path(@map), alert: "failed: #{@role.errors.full_messages.to_sentence}"
    end
  end

  def destroy
    @map = @role.map
    if @role.destroy
      redirect_to map_roles_path(@map), alert: t("helpers.message.role.destroyed")
    else
      redirect_to map_roles_path(@map), alert: "failed: #{@role.errors.full_messages.to_sentence}"
    end
  end

  private

  def set_role
    @role = authorize Role.find(params[:id])
  end

  def create_role_params
    params.require(:role).permit(:role_type, user_attributes: [:email])
  end

  def update_role_params
    params.require(:role).permit(:role_type)
  end
end
