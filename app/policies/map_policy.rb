class MapPolicy < ApplicationPolicy
  def user_owns_record
    record.user_id == user&.id
  end

  def show? = user_owns_record

  def edit? = user_owns_record

  def update? = user_owns_record

  def destroy? = user_owns_record

  def schema? = user_owns_record

  def geojson? = user_owns_record
end
