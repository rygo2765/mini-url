require "application_system_test_case"

class UrlsTest < ApplicationSystemTestCase
  setup do
    @url = urls(:one)
  end

  test "visiting the index" do
    visit urls_url
    assert_selector "h1", text: "Urls"
  end

  test "should create url" do
    visit urls_url
    click_on "New url"

    fill_in "Short url", with: @url.short_url
    fill_in "Target url", with: @url.target_url
    fill_in "Title", with: @url.title
    click_on "Create Url"

    assert_text "Url was successfully created"
    click_on "Back"
  end

  test "should update Url" do
    visit url_url(@url)
    click_on "Edit this url", match: :first

    fill_in "Short url", with: @url.short_url
    fill_in "Target url", with: @url.target_url
    fill_in "Title", with: @url.title
    click_on "Update Url"

    assert_text "Url was successfully updated"
    click_on "Back"
  end

  test "should destroy Url" do
    visit url_url(@url)
    click_on "Destroy this url", match: :first

    assert_text "Url was successfully destroyed"
  end
end
