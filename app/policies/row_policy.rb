class RowPolicy < ApplicationPolicy
  def new? = edit?

  def create? = edit?

  def show?
    edit? || role&.viewer?
  end

  def edit?
    destroy? || role&.contributor?
  end

  def update? = edit?

  def destroy?
    role&.owner? || role&.editor?
  end

  private

  def role
    Role.find_by(map: record.layer.map, user: user)
  end
end
