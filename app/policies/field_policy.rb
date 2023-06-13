class FieldPolicy < ApplicationPolicy
  def new? = create?

  def create? = map_access&.is_at_least(:editor)

  def show? = map_access.present?

  def edit? = create?

  def update? = create?

  def destroy? = create?

  private

  def map_access
    @map_access ||= user.access_for_map(record.layer.map)
  end
end
