require "rails_helper"

RSpec.describe "Event sync histories", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  describe "GET /event_sync_histories" do
    it "shows an enabled sync button when no sync has run" do
      get event_sync_histories_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Event sync history")
      expect(response.body).to include("Sync events")
      expect(response.body).to include("No syncs yet")
      expect(response.body).not_to include("disabled")
    end

    it "shows sync times in the application time zone" do
      Time.use_zone("Kolkata") do
        FactoryBot.create(
          :event_sync_history,
          status: "sync_success",
          created_at: Time.utc(2026, 10, 6, 7, 45),
          updated_at: Time.utc(2026, 10, 6, 7, 50)
        )

        get event_sync_histories_path

        expect(response.body).to include("6 October 2026, 13:15")
        expect(response.body).to include("6 October 2026, 13:20")
        expect(response.body).not_to include("6 October 2026, 07:45")
      end
    end

    it "disables the sync button for two hours after the last sync" do
      travel_to(Time.zone.parse("2026-10-06 12:00:00")) do
        FactoryBot.create(
          :event_sync_history,
          status: "sync_success",
          created_at: Time.zone.parse("2026-10-06 11:00:00"),
          updated_at: Time.zone.parse("2026-10-06 11:05:00")
        )

        get event_sync_histories_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("disabled")
        expect(response.body).to include("Sync is available again at 6 October 2026, 13:00")
        expect(response.body).to include("Sync success")
      end
    end
  end

  describe "POST /event_sync_histories" do
    it "records a sync and enqueues ingest" do
      expect {
        post event_sync_histories_path
      }.to change(EventSyncHistory, :count).by(1)
        .and have_enqueued_job(EventSyncJob)

      expect(response).to redirect_to(event_sync_histories_path)
      expect(flash[:notice]).to eq("Event sync started.")
      expect(EventSyncHistory.last).to be_draft
      expect(EventSyncJob).to have_been_enqueued.with(EventSyncHistory.last.id)
    end

    it "does not start another sync during the cooldown" do
      FactoryBot.create(:event_sync_history, created_at: 15.minutes.ago, updated_at: 15.minutes.ago)

      expect {
        post event_sync_histories_path
      }.not_to change(EventSyncHistory, :count)

      expect(response).to redirect_to(event_sync_histories_path)
      expect(flash[:alert]).to include("Sync is available again at")
      expect(EventSyncJob).not_to have_been_enqueued
    end
  end
end
