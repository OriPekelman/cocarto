class FieldPolicy < ApplicationPolicy
  def new? = create?

  def create? = access_group&.owner? || access_group&.editor?

  def show? = access_group.present?

  def edit? = create?

  def update? = create?

  def destroy? = create?

  private

  def access_group
    user.access_groups.find_by(map: record.layer.map)
  end
end
