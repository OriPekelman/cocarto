class MapPolicy < ApplicationPolicy
  def user_owns_record
    return false if user.nil?

    if record.new_record?
      record.roles.find{ _1.owner? && _1.user == user }.present?
    else
      record.roles.owner.merge(user.roles).exists?
    end
  end

  def create? = user_owns_record

  def show? = user_owns_record

  def update? = user_owns_record

  def destroy? = user_owns_record

  class Scope < Scope
    def resolve = user.maps
  end
end
