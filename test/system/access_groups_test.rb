require "application_system_test_case"

class AccessGroupsTest < ApplicationSystemTestCase
  test "the map owner can see the roles" do
    sign_in_as(users("reclus"), "refleurir")
    visit map_path(id: maps("boat"))
    assert_text "Boating trip"
    click_link "Share…"
    assert_field "access_group_users_attributes_0_email", with: "elisee.reclus@commune.paris"
    assert_field "access_group_users_attributes_0_email", with: "cassini@carto.gouv.fr"

    sign_out
    visit map_path(id: maps("boat"))
    assert_no_text "Boating trip"
  end

  test "a viewer can see the map, but not the roles" do
    sign_in_as(users("cassini"), "générations12345")
    visit map_path(id: maps("boat"))
    assert_no_link "Share…"
  end
end
