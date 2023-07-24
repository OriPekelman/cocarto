class Import::MappingPolicy < ApplicationPolicy
  def new? = create?

  def create? = map_access&.is_at_least(:editor)

  def update? = create?

  def destroy? = create?

  private

  def map_access
    @map_access ||= user.access_for_map(record.configuration.map)
  end
end
