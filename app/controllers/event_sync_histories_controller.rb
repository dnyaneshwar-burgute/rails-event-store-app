class EventSyncHistoriesController < ApplicationController
  def index
    @event_sync_histories = EventSyncHistory.recent
    @sync_on_cooldown = EventSyncHistory.sync_on_cooldown?
    @cooldown_ends_at = EventSyncHistory.cooldown_ends_at if @sync_on_cooldown
  end

  def create
    history = EventSyncHistory.record_sync_request
    if history
      EventSyncJob.perform_later(history.id)
      redirect_to event_sync_histories_path, notice: "Event sync started."
    else
      redirect_to event_sync_histories_path,
        alert: "Sync is available again at #{helpers.sync_time(EventSyncHistory.cooldown_ends_at)}."
    end
  end
end
