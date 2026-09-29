require "rails_helper"

RSpec.describe "Events", type: :request do
  describe "GET /events" do
    let!(:events) { FactoryBot.create_list(:event, 3) }

    context "when the user is signed out" do
      before { stub_unauthenticated_clerk }

      it "shows the public events and a sign up button" do
        get events_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Public events")
        expect(response.body).to include("sign-up-button")
        expect(response.body).to include("Sign up")
        expect(response.body).not_to include("Sign out")
        events.each do |event|
          expect(response.body).to include(event.title)
        end
      end
    end

    context "when the user is signed in" do
      before { stub_clerk_auth }

      it "shows a sign out button" do
        get events_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("sign-out-button")
        expect(response.body).to include("Sign out")
        expect(response.body).to include("Test Voter")
        expect(response.body).not_to include("sign-up-button")
        events.each do |event|
          expect(response.body).to include(event.title)
        end
      end
    end
  end
end
