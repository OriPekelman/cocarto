require "application_system_test_case"

class MapSharingTest < ApplicationSystemTestCase
  test "the map owner can see the roles" do
    sign_in_as(users("reclus"), "refleurir")
    visit map_path(id: maps("boat"))
    click_link "Sharing and permissions"

    assert_field "user_role_user_attributes_email", with: "elisee.reclus@commune.paris"
    assert_field "user_role_user_attributes_email", with: "cassini@carto.gouv.fr"
  end

  test "a viewer can see the map, but not the roles" do
    sign_in_as(users("cassini"), "générations12345")
    visit map_path(id: maps("boat"))

    assert_no_link "Sharing and permissions"
  end

  test "generate a link for an anonymous access" do
    # Let’s be sure we can’t access the page
    maps("boat").map_tokens.destroy_all
    visit map_path(id: maps("boat"))

    assert_no_field "Name"

    # Create a link
    sign_in_as(users("reclus"), "refleurir")
    visit map_path(id: maps("boat"))
    click_link "Sharing and permissions"
    click_link "Links"

    new_link = find_by_id("new_map_token")
    new_link.select("Editor", from: "Role")
    new_link.fill_in("Description", with: "Test link")
    click_button "Create link"

    url = find("input", id: "url_to_share").value
    click_button "Close"

    # We sign out and we can access the page
    sign_out
    visit(url)

    assert_field "Name", with: "Boating trip"
  end
end
