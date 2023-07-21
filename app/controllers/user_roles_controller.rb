class UserRolesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_role, only: %i[update destroy]

  def index
    @user_roles = policy_scope(UserRole).where(map_id: params["map_id"])
    @map = Map.find(params["map_id"])

    @new_role = @map.user_roles.new(user: User.new)
  end

  def create
    map = Map.find(params["map_id"])
    user_role = authorize map.user_roles.new(create_params)

    user = user_role.user
    if user.new_record?
      user.skip_invitation = true
      user.invite!
    end
    if user_role.save
      user.deliver_invitation if user.previously_new_record?
      redirect_to map_user_roles_path(map), notice: t("helpers.message.user_role.created")
    else
      redirect_to map_user_roles_path(map), alert: t("common.failed", msg: user_role.errors.full_messages.to_sentence)
    end
  end

  def update
    @map = @user_role.map
    if @user_role.update(update_params)
      redirect_to map_user_roles_path(@map), notice: t("helpers.message.user_role.updated")
    else
      redirect_to map_user_roles_path(@map), alert: t("common.failed", msg: @user_role.errors.full_messages.to_sentence)
    end
  end

  def destroy
    @map = @user_role.map
    if @user_role.destroy
      redirect_to map_user_roles_path(@map), alert: t("helpers.message.user_role.destroyed"), status: :see_other
    else
      redirect_to map_user_roles_path(@map), alert: t("common.failed", msg: @user_role.errors.full_messages.to_sentence), status: :see_other
    end
  end

  private

  def set_user_role
    @user_role = authorize UserRole.find(params[:id])
  end

  def create_params
    create_params = params.require(:user_role).permit(:role_type, user_attributes: [:email])
    email = create_params.dig(:user_attributes, :email)
    if email.present?
      existing_user = User.find_by(email: email)
      if existing_user.present?
        create_params.delete(:user_attributes)
        create_params[:user] = existing_user
      end
    end

    create_params
  end

  def update_params
    params.require(:user_role).permit(:role_type)
  end
end
