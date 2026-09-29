require "rails_helper"

RSpec.describe VotesController, type: :controller do
  let(:event) { FactoryBot.create(:event) }
  let(:user_id) { SecureRandom.uuid }

  describe "POST create" do
    context "when the user is signed in" do
      before { stub_clerk_auth(user_id: user_id) }

      it "records an upvote and redirects to the events index" do
        post :create, params: { event_id: event.id, choice: "upvote" }

        expect(response).to redirect_to(events_path)
        expect(flash[:notice]).to eq("Vote recorded.")
        expect(event.votes.find_by!(clerk_user_id: user_id).choice).to eq("upvote")
      end

      it "records a downvote and redirects to the events index" do
        post :create, params: { event_id: event.id, choice: "downvote" }

        expect(response).to redirect_to(events_path)
        expect(flash[:notice]).to eq("Vote recorded.")
        expect(event.votes.find_by!(clerk_user_id: user_id).choice).to eq("downvote")
      end

      it "redirects with an alert when the choice is invalid" do
        post :create, params: { event_id: event.id, choice: "maybe" }

        expect(response).to redirect_to(events_path)
        expect(flash[:alert]).to eq("Choose like or dislike.")
        expect(event.votes).to be_empty
      end

      it "redirects with an alert when the event does not exist" do
        post :create, params: { event_id: 0, choice: "upvote" }

        expect(response).to redirect_to(events_path)
        expect(flash[:alert]).to eq("Event not found.")
        expect(Vote.count).to eq(0)
      end
    end

    context "when the user is signed out" do
      before { stub_unauthenticated_clerk }

      it "redirects to the Clerk sign-in url" do
        post :create, params: { event_id: event.id, choice: "upvote" }

        expect(response).to redirect_to("https://example.test/sign-in")
        expect(event.votes).to be_empty
      end
    end
  end
end
