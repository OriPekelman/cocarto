class LayerPolicy < ApplicationPolicy
  def user_owns_record
    return false if user.nil?

    record.map.roles.owner.merge(user.roles).exists?
  end

  def show? = Role.exists?(map: record.map, user: user)

  def schema? = show?

  def geojson? = show?

  def edit? = user_owns_record

  def update? = user_owns_record

  def destroy? = user_owns_record
end
