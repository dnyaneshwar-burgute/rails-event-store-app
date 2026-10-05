require "rails_helper"

RSpec.describe Vote, type: :model do
  describe "associations" do
    it { should belong_to(:event) }
  end

  describe "validations" do
    subject { FactoryBot.create(:vote) }

    it { should validate_presence_of(:clerk_user_id) }
    it { should validate_inclusion_of(:choice).in_array(Vote::CHOICES) }
    it { should validate_uniqueness_of(:clerk_user_id).scoped_to(:event_id) }
  end
end
