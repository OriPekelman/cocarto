require "application_system_test_case"

class RolesTest < ApplicationSystemTestCase
  test "the map owner can see the roles" do
    sign_in_as(users("reclus"), "refleurir")
    visit map_path(id: maps("boat"))
    click_link "Share…"
    assert_field "role_user_attributes_email", with: "elisee.reclus@commune.paris"
    assert_field "role_user_attributes_email", with: "cassini@carto.gouv.fr"
  end

  test "a viewer can see the map, but not the roles" do
    sign_in_as(users("cassini"), "générations12345")
    visit map_path(id: maps("boat"))
    assert_no_link "Share…"
  end
end
