class RolePolicy < ApplicationPolicy
  # Only owners can see or modify the roles of a map;
  def index? = user_is_owner?

  def create? = user_is_owner?

  def update? = user_is_owner?

  def destroy? = user_is_owner?

  private

  def user_is_owner?
    record.map.roles.owner.merge(user.roles).exists?
  end

  class Scope < Scope
    def resolve
      scope.where(map: @user.maps.merge(Role.owner))
    end
  end
end
