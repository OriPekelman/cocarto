class LayerPolicy < ApplicationPolicy
  def show? = role.present?

  def schema? = show?

  def geojson? = show?

  def edit? = update? || role&.contributor?

  def update? = role&.owner? || role&.editor?

  def destroy? = role&.owner?

  private

  def role
    Role.find_by(map: record.map, user: user)
  end
end
