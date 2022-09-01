class RolePolicy < ApplicationPolicy
  # For now we say that only the owner can see and modify the roles
  # We will probably change that at some point (like all editors can see all roles)
  def index?
    record.owner.merge(user.roles).exists?
  end

  def create? = user_is_owner?

  def update? = user_is_owner?

  def destroy? = user_is_owner?

  private

  def user_is_owner?
    record.map.roles.owner.merge(user.roles).exists?
  end

  class Scope < Scope
    def resolve = scope.all
  end
end
