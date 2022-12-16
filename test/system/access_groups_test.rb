require "application_system_test_case"

class AccessGroupsTest < ApplicationSystemTestCase
  test "the map owner can see the roles" do
    sign_in_as(users("reclus"), "refleurir")
    visit map_path(id: maps("boat"))
    click_link "Share…"

    assert_field "access_group_users_attributes_0_email", with: "elisee.reclus@commune.paris"
    assert_field "access_group_users_attributes_0_email", with: "cassini@carto.gouv.fr"
  end

  test "a viewer can see the map, but not the roles" do
    sign_in_as(users("cassini"), "générations12345")
    visit map_path(id: maps("boat"))

    assert_no_link "Share…"
  end

  test "we can generate a link for an anonymous access" do
    # Let’s be sure we can’t access the page
    visit map_path(id: maps("boat"))

    assert_no_field "Name"

    # Create a link
    sign_in_as(users("reclus"), "refleurir")
    visit map_path(id: maps("boat"))
    click_link "Share…"

    new_link = find_by_id("new_access_group_by_token")
    new_link.fill_in("access_group_name", with: "Test link")
    new_link.find_button("Create").click
    url = find("input", id: "url_to_share").value

    # We sign out and we can access the page
    sign_out
    visit(url)

    assert_field "Name", with: "Boating trip"
  end
end
