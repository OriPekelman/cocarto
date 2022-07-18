class LayerPolicy < ApplicationPolicy
  def user_owns_record
    return false if user.nil?

    record.map.roles.owner.merge(user.roles).exists?
  end

  def show? = user_owns_record

  def edit? = user_owns_record

  def update? = user_owns_record

  def destroy? = user_owns_record

  def schema? = user_owns_record

  def geojson? = user_owns_record
end
