require "rails_helper"

RSpec.describe Event, type: :model do
  describe "associations" do
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
end
