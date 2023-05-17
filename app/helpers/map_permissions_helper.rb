module MapPermissionsHelper
  def options_for_role_type_select(record)
    UserRole.human_attribute_name("role_types.owner")
    options = record.class.role_types.map do |role_type|
      [record.class.human_attribute_name("role_types.#{role_type[0]}"), role_type[1]]
    end
    options_for_select(options, record.role_type)
  end
end
