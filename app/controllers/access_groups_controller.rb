class AccessGroupsController < ApplicationController
  before_action :set_access_group, only: %i[update destroy]

  def index
    @map = current_user.maps.find(params["map_id"])

    authorize @map.access_groups.new
    @access_groups = policy_scope(@map.access_groups).includes(:users)
  end

  def create
    @map = current_user.maps.find(params["map_id"])
    @access_group = authorize @map.access_groups.new(create_access_group_params)

    if @access_group.save
      @access_group.users.each do |user|
        if user.invitation_sent_at.blank?
          user.invite!
        end
      end
      redirect_to map_access_groups_path(@map), notice: t("helpers.message.access_group.created")
    else
      redirect_to map_access_groups_path(@map), alert: "failed: #{@access_group.errors.full_messages.to_sentence}"
    end
  end

  def update
    @map = @access_group.map
    if @access_group.update(update_access_group_params)
      redirect_to map_access_groups_path(@map), notice: t("helpers.message.access_group.updated")
    else
      redirect_to map_access_groups_path(@map), alert: "failed: #{@access_group.errors.full_messages.to_sentence}"
    end
  end

  def destroy
    @map = @access_group.map
    if @access_group.destroy
      redirect_to map_access_groups_path(@map), alert: t("helpers.message.access_group.destroyed")
    else
      redirect_to map_access_groups_path(@map), alert: "failed: #{@access_group.errors.full_messages.to_sentence}"
    end
  end

  private

  def set_access_group
    @access_group = authorize AccessGroup.find(params[:id])
  end

  def create_access_group_params
    params.require(:access_group).permit(:role_type, users_attributes: [:email])
  end

  def update_access_group_params
    params.require(:access_group).permit(:role_type)
  end
end
