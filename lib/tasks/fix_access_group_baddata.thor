class FixAccessGroupBaddata < Thor
  desc "access_groups", "Fix access_group bad data"
  def access_groups
    # Note: this is a temporary task, that will probably never be run in production and will be removed before #257 is done.
    # it serves mainly as a notepad for the bad data cleanup to be run manually, or even via the user interface.

    user_specific_groups_with_several_users = AccessGroup.joins(:users).where(token: nil).filter { _1.users.count != 1 } # .to_h { [_1.id, _1.users.count] }
    # Manual cleanup 2022-05-09 : there was one access group in this case, one of the user was actually anonymous, and had no other contribution. Deleted it.
    user_specific_groups_with_several_users.each do |access_group|
      # move each user (except the first) to their own new group
      access_group.users[1..].each do |user|
        access_group.users.destroy(user)
        AccessGroup.create(map: access_group.map, role_type: access_group.role_type, users: [user])
      end
    end

    user_specific_groups_with_a_name = AccessGroup.joins(:users).where(token: nil).where.not(name: nil) # .pluck(:id, :name)
    # Manual cleanup 2022-05-09 : cleared the name of 34 user-specific groups
    user_specific_groups_with_a_name.each do |access_group|
      access_group.update(name: nil)
    end

    token_groups_with_nil_name = AccessGroup.joins(:users).where.not(token: nil).where(name: nil) # .pluck(:id, :name)
    # Manual cleanup 2022-05-09 : no token group with a nil name
    token_groups_with_nil_name.each do |access_group|
      access_group.update(name: t("activerecord.attributes.access_group.token_group"))
    end

    token_groups_with_blank_name = AccessGroup.joins(:users).where.not(token: nil).where(name: "") # .pluck(:id, :name)
    # Manual cleanup 2022-05-09 : 7 access groups renamed "Lien de partage"
    token_groups_with_blank_name.each do |access_group|
      access_group.update(name: t("activerecord.attributes.access_group.token_group"))
    end

    token_groups_with_email_users = AccessGroup.joins(:users).where.not(token: nil).filter { _1.users.where.not(email: nil).exists? } # .to_h{ [_1.id, _1.users.where.not(email: nil).count] }
    # Manual inspection 2022-05-09 : 13 access groups in this case
    token_groups_with_email_users.each do |access_group|
      access_group.users.where.not(email: nil).each do |user|
        access_group.users.destroy(user)
        AccessGroup.create(map: access_group.map, role_type: access_group.role_type, users: [user])
      end
    end

    # > Map.joins(:users).group("maps.id, users.id").having("count(*) > 1").count
    # Manual inspection 2022-05-09 : 13 maps in this case
  end
end
