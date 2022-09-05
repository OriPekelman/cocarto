class FieldPolicy < ApplicationPolicy
  def new? = create?

  def create? = role&.owner? || role&.editor?

  def show? = role.present?

  def edit? = create?

  def update? = create?

  def destroy? = create?

  private

  def role
    Role.find_by(map: record.layer.map, user: user)
  end
end
