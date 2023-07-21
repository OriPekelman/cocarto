require "application_system_test_case"

class MapSharingTest < ApplicationSystemTestCase
  test "the map owner can see the roles" do
    sign_in_as(users("reclus"), "refleurir")
    visit map_path(id: maps("boat"))
    click_link "Share"

    assert_field "user_role_user_attributes_email", with: "elisee.reclus@commune.paris"
    assert_field "user_role_user_attributes_email", with: "cassini@carto.gouv.fr"
  end

  test "a viewer can see the map, but not the roles" do
    sign_in_as(users("cassini"), "générations12345")
    visit map_path(id: maps("boat"))

    assert_no_link "Share"
  end

  test "generate a link for an anonymous access" do
    # Let’s be sure we can’t access the page
    maps("boat").map_tokens.destroy_all
    visit map_path(id: maps("boat"))

    assert_no_field "Name"

    # Create a link
    sign_in_as(users("reclus"), "refleurir")
    visit map_path(id: maps("boat"))
    click_link "Share"
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

    assert_selector "h2", text: "Boating trip"
  end

  test "anonymous access" do
    visit map_shared_url(token: map_tokens(:restaurants_contributors).token)
    visit map_shared_url(token: map_tokens(:boat_viewers).token)
    click_link "Maps"

    assert_text "Restaurants"
    assert_text "Boating trip"
  end

  test "anonymous access then sign in" do
    users(:bakounine).user_roles.destroy_all

    visit map_shared_url(token: map_tokens(:restaurants_contributors).token)
    sign_in_as(users(:bakounine), "refleurir")
    click_link "Restaurants"

    assert_selector "h2", text: "Restaurants"

    sign_out
    visit maps_url

    assert_text "You need to sign in or sign up before continuing."
  end

  test "anonymous access then sign up" do
    visit map_shared_url(token: map_tokens(:restaurants_contributors).token)
    wait_until_dropdown_controller_ready
    click_button "anonymous"
    click_link "Sign up"
    fill_in "user_email", with: "cabiai@amazonas.br"
    fill_in "user_password", with: "canne à sucre"
    fill_in "user_password_confirmation", with: "canne à sucre"
    click_button "Sign up"
    click_link "Restaurants"

    assert_selector "h2", text: "Restaurants"

    sign_out
    visit maps_url

    assert_text "You need to sign in or sign up before continuing."
  end
end
