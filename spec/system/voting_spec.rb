require "rails_helper"
require "capybara/rspec"

RSpec.describe "Voting on public events", type: :system, capybara_feature: true do
  background do
    stub_unauthenticated_clerk(
      sign_in_url: "/events?test_user=#{ClerkHelpers::DEFAULT_USER_ID}",
      sign_up_url: "/sign-up"
    )
    # To check in a browser live
    # driven_by(:selenium_chrome)
    driven_by(:selenium_chrome_headless)
    @events = FactoryBot.create_list(:event, 3)
    visit events_path
  end

  it "updates the like count on the page after signing in" do
    expect(page).to have_css("h1", text: "Public events")
    @events.each do |event|
      expect(page).to have_content(event.title)
    end
    expect(page).to have_link("Sign up")

    click_link "Sign in to vote", match: :first
    expect(page).to have_content("Test Voter")
    expect(page).to have_button("Sign out")

    event = @events.first
    within(".event-card", text: event.title) do
      expect(page).to have_content("0 likes")
      click_button "Like"
    end

    within(".event-card", text: event.title) do
      expect(page).to have_content("1 like")
    end

    click_sign_out
    expect(page).to have_link("Sign up")
  end

  scenario "sets the dislike count to 1 and the like count to 0" do
    expect(page).to have_link("Sign up")

    click_link "Sign in to vote", match: :first
    expect(page).to have_button("Sign out")

    event = @events.first
    within(".event-card", text: event.title) do
      expect(page).to have_content("0 likes")
      expect(page).to have_content("0 dislikes")
      click_button "Dislike"
    end

    within(".event-card", text: event.title) do
      expect(page).to have_content("0 likes")
      expect(page).to have_content("1 dislike")
    end

    click_sign_out
    expect(page).to have_link("Sign up")
  end
end
