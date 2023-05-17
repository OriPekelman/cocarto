class MapPolicy < ApplicationPolicy
  def create? = map_access&.is_at_least(:owner)

  def show? = map_access.present?

  def shared? = show?

  def update? = create?

  def destroy? = create?

  class Scope < Scope
    def resolve = user.maps
  end

  private

  def map_access
    @map_access ||= user.access_for_map(record)
  end
end
