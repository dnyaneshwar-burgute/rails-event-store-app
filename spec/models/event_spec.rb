require "rails_helper"

RSpec.describe Event, type: :model do
  describe "associations" do
    subject { FactoryBot.build(:event) }

    it { is_expected.to have_many(:votes).dependent(:destroy) }
  end

  describe "validations" do
    subject { FactoryBot.build(:event) }
    it { should validate_presence_of(:billetto_id).with_message('^Billetto Id should be present') }
    it { should validate_uniqueness_of(:billetto_id).with_message('^Billetto Id is already taken') }

    it { should validate_presence_of(:title).with_message('^Title should be present') }
    it { should validate_presence_of(:starts_at).with_message('^Starts At should be present') }

    it do
      is_expected.to validate_numericality_of(:upvotes_count)
        .only_integer
        .is_greater_than_or_equal_to(0)
    end

    it do
      is_expected.to validate_numericality_of(:downvotes_count)
        .only_integer
        .is_greater_than_or_equal_to(0)
    end
  end

  describe "#brief_description" do
    it "returns the description when one is present" do
      event = FactoryBot.build(:event, description: "Live jazz downtown.")

      expect(event.brief_description).to eq("Live jazz downtown.")
    end

    it "returns a fallback when the description is missing" do
      event = FactoryBot.build(:event, description: nil)

      expect(event.brief_description).to eq("No description")
    end

    it "returns a fallback when the description is blank" do
      event = FactoryBot.build(:event, description: "  ")

      expect(event.brief_description).to eq("No description")
    end
  end

  describe "#vote_for" do
    let(:event) { FactoryBot.create(:event) }
    let(:user_id) { SecureRandom.uuid }
    let!(:vote) { FactoryBot.create(:vote, event: event, clerk_user_id: user_id, choice: "upvote") }

    it "returns nil when the user id is blank" do
      expect(event.vote_for(nil)).to be_nil
      expect(event.vote_for("")).to be_nil
    end

    it "returns nil when the user has not voted" do
      expect(event.vote_for(SecureRandom.uuid)).to be_nil
    end

    it "finds the user's vote from the database" do
      expect(event.votes).not_to be_loaded
      expect(event.vote_for(user_id)).to eq(vote)
    end

    it "finds the user's vote from the already loaded association" do
      event.votes.load

      queries = []
      callback = ->(_name, _start, _finish, _id, payload) { queries << payload[:sql] }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(event.vote_for(user_id)).to eq(vote)
      end

      expect(queries).to be_empty
    end
  end
end
