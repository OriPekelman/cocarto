class RowPolicy < ApplicationPolicy
  def new?
    access_group&.owner? || access_group&.editor? || access_group&.contributor?
  end

  def create? = new?

  # A contributor can only update its own fields
  # Owner and editor can always update
  def update?
    access_group&.owner? || access_group&.editor? || (access_group&.contributor? && user == record.author)
  end

  def destroy?
    access_group&.owner? || access_group&.editor?
  end

  # This method is used to generate data-attributes
  # that will be used to disable client-side some features
  def self.authorizations(row)
    if row
      %W[owner editor contributor-#{row.author_id}].to_json
    else
      %W[owner editor].to_json
    end
  end

  private

  def access_group
    user.access_groups.find_by(map: record.layer.map)
  end
end
