class Import::OperationPolicy < ApplicationPolicy
  def new? = create?

  def create? = map_access&.is_at_least(:contributor)

  def show? = create?

  def update? = create?

  def destroy? = create?

  class Scope < Scope
    def resolve
      scope.joins(:map).where(maps: user.maps.where(user_roles: {role_type: [:owner, :editor, :contributor]}))
    end
  end

  private

  def map_access
    @map_access ||= user.access_for_map(record.configuration.map)
  end
end
