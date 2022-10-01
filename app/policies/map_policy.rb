class MapPolicy < ApplicationPolicy
  def user_owns_record
    return false if user.nil?

    if record.new_record?
      record.access_groups.find { _1.owner? && _1.users.include?(user) }.present?
    else
      record.access_groups.owner.merge(user.access_groups).exists?
    end
  end

  def create? = user_owns_record

  def show? = user&.access_groups&.find_by(map: record).present?

  def update? = user_owns_record

  def destroy? = user_owns_record

  class Scope < Scope
    def resolve = user.maps
  end
end
