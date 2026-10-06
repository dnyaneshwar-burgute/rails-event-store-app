require "rails_helper"

RSpec.describe EventSyncHistory, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe "validations" do
    it { should validate_inclusion_of(:status).in_array(EventSyncHistory::STATUSES) }
  end

  describe "state machine" do
    it "starts as draft and can succeed" do
      history = FactoryBot.create(:event_sync_history)

      expect(history).to be_draft
      history.initiate_sync!
      expect(history).to be_sync_initiated
      history.succeed!
      expect(history.reload).to be_sync_success
    end

    it "can fail after sync starts" do
      history = FactoryBot.create(:event_sync_history)
      history.initiate_sync!

      history.fail_sync!

      expect(history.reload).to be_sync_failed
    end

    it "does not succeed from draft" do
      history = FactoryBot.create(:event_sync_history)

      expect { history.succeed! }.to raise_error(AASM::InvalidTransition)
      expect(history.reload).to be_draft
    end
  end

  describe ".sync_on_cooldown?" do
    it "is false when there is no sync history" do
      expect(described_class.sync_on_cooldown?).to eq(false)
    end

    it "is true for two hours after the last sync record" do
      travel_to(Time.zone.parse("2026-10-06 12:00:00")) do
        FactoryBot.create(:event_sync_history, status: "sync_success", created_at: 30.minutes.ago, updated_at: 30.minutes.ago)

        expect(described_class.sync_on_cooldown?).to eq(true)
        expect(described_class.cooldown_ends_at).to eq(Time.zone.parse("2026-10-06 13:30:00"))
      end
    end

    it "is false once two hours have passed" do
      travel_to(Time.zone.parse("2026-10-06 12:00:00")) do
        FactoryBot.create(:event_sync_history, created_at: 2.hours.ago, updated_at: 2.hours.ago)

        expect(described_class.sync_on_cooldown?).to eq(false)
      end
    end
  end

  describe ".record_sync_request" do
    it "creates a draft record when sync is allowed" do
      history = described_class.record_sync_request

      expect(history).to be_draft
      expect(described_class.count).to eq(1)
    end

    it "returns nil during the cooldown" do
      FactoryBot.create(:event_sync_history, created_at: 10.minutes.ago, updated_at: 10.minutes.ago)

      expect(described_class.record_sync_request).to be_nil
      expect(described_class.count).to eq(1)
    end
  end
end
