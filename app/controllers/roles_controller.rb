class RolesController < ApplicationController
  before_action :set_role, only: %i[update destroy]

  def index
    @map = current_user.maps.find(params["map_id"])
    @roles = @map.roles.includes(:user)
  end

  def create
    @map = current_user.maps.find(params["map_id"])
    create_params = create_role_params
    if (existing_user = User.find_by(email: create_params.dig(:user_attributes, :email)))
      create_params.delete(:user_attributes)
      create_params[:user] = existing_user
    end

    @role = @map.roles.new(create_params)

    if @role.save
      if @role.user.invitation_sent_at.blank?
        @role.user.invite!
      end
      redirect_to action: :index, notice: t("helpers.message.role.created")
    else
      redirect_to action: :index, error: "failed: #{@role.errors}"
    end
  end

  def update
    @map = @role.map
    if @role.update(update_role_params)
      redirect_to action: :index, notice: t("helpers.message.role.updated")
    else
      redirect_to action: :index, error: "failed"
    end
  end

  def destroy
    @role.destroy

    redirect_to action: :index, notice: t("helpers.message.role.destroyed")
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def create_role_params
    params.require(:role).permit(:role_type, user_attributes: [:email])
  end

  def update_role_params
    params.require(:role).permit(:role_type)
  end
end
