class UserRolePolicy < ApplicationPolicy
  # Only owners can see or modify the roles of a map;
  def index? = map_access&.is_at_least(:owner)

  def create? = index?

  def update? = index?

  def destroy? = index?

  class Scope < Scope
    def resolve
      scope.where(map: user.maps.merge(UserRole.owner))
    end
  end

  private

  def map_access
    @map_access ||= user.access_for_map(record.map)
  end
end
