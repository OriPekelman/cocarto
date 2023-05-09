class AccessGroupsController < ApplicationController
  before_action :authenticate_user!, except: :enter_by_link
  before_action :set_access_group, only: %i[update destroy]

  def index
    @access_groups = policy_scope(AccessGroup).where(map_id: params["map_id"])
    @map = Map.find(params["map_id"])

    @new_group = authorize @map.access_groups.new

    if params[:scope] == "with_token"
      @access_groups = @access_groups.with_token
      @new_group.token = AccessGroup.new_token
    else
      @access_groups = @access_groups.user_specific
      @new_group.users << User.new
    end
  end

  def create
    map = Map.find(params["map_id"])
    access_group = authorize map.access_groups.new(create_access_group_params)

    if access_group.save
      access_group.users.each do |user|
        if user.invitation_sent_at.blank?
          user.invite!
        end
      end
      redirect_to collection_index_path(access_group), notice: t("helpers.message.access_group.created")
    else
      redirect_to collection_index_path(access_group), alert: t("common.failed", msg: access_group.errors.full_messages.to_sentence)
    end
  end

  def collection_index_path(access_group)
    map_access_groups_path(access_group.map, scope: access_group.token.present? ? "with_token" : "user_specific")
  end

  # Someone access the page through a link
  # If the user is signed in we add them to the users list of that access group
  # Other wise, we create a user without email
  def enter_by_link
    skip_authorization
    access_group = AccessGroup.find_by(token: params[:token])
    if user_signed_in?
      access_group.users << current_user unless access_group.users.exists?(current_user.id)
    else
      user = access_group.users.create(email: nil, remember_me: false)
      sign_in user
    end
    redirect_to access_group.map
  end

  def update
    @map = @access_group.map
    if @access_group.update(update_access_group_params)
      redirect_to collection_index_path(@access_group), notice: t("helpers.message.access_group.updated")
    else
      redirect_to collection_index_path(@access_group), alert: t("common.failed", msg: @access_group.errors.full_messages.to_sentence)
    end
  end

  def destroy
    @map = @access_group.map
    if @access_group.destroy
      redirect_to collection_index_path(@access_group), alert: t("helpers.message.access_group.destroyed")
    else
      redirect_to collection_index_path(@access_group), alert: t("common.failed", msg: @access_group.errors.full_messages.to_sentence)
    end
  end

  private

  def set_access_group
    @access_group = authorize AccessGroup.find(params[:id])
  end

  def create_access_group_params
    create_params = params.require(:access_group).permit(:role_type, :token, :name, users_attributes: [:email])
    email = create_params.dig(:users_attributes, "0", :email)
    if email.present?
      existing_user = User.find_by(email: create_params.dig(:users_attributes, "0", :email))
      if existing_user.present?
        create_params.delete(:users_attributes)
        create_params[:users] = [existing_user]
      end
    end

    create_params
  end

  def update_access_group_params
    params.require(:access_group).permit(:role_type, :name)
  end
end
