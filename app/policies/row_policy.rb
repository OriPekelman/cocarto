class RowPolicy < ApplicationPolicy
  def new?
    role&.owner? || role&.editor? || role&.contributor?
  end

  def create? = new?

  # A contributor can only update its own fields
  # Owner and editor can always update
  def update?
    role&.owner? || role&.editor? || (role&.contributor? && user == record.author)
  end

  def destroy?
    role&.owner? || role&.editor?
  end

  private

  def role
    Role.find_by(map: record.layer.map, user: user)
  end
end
