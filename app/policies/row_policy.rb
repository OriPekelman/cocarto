class RowPolicy < ApplicationPolicy
  def show? = map_access&.is_at_least(:viewer)

  def new? = create?

  def create? = map_access&.is_at_least(:contributor)

  # A contributor can only update its own fields
  # Owner and editor can always update
  def update?
    map_access&.is_at_least(:editor) ||
      (map_access&.is_at_least(:contributor) && (user == record.author || user.anonymous_tag == record.anonymous_tag))
  end

  def destroy? = map_access&.is_at_least(:editor)

  # This method is used to generate data-attributes
  # that will be used to disable client-side some features
  def self.authorizations(row)
    %W[owner editor contributor-#{row.author_id}].to_json
  end

  private

  def map_access
    @map_access ||= user.access_for_map(record.layer.map)
  end
end
