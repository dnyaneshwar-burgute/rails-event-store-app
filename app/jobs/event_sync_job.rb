class EventSyncJob < ApplicationJob
  queue_as :default

  discard_on(StandardError) do |job, error|
    history = EventSyncHistory.find_by(id: job.arguments.first)
    history.fail_sync! if history&.may_fail_sync?
    Rails.logger.error("Event sync #{job.arguments.first} failed: #{error.class}: #{error.message}")
  end

  def perform(event_sync_history_id)
    history = EventSyncHistory.find(event_sync_history_id)
    return unless history.may_initiate_sync?

    history.initiate_sync!
    Events::Ingest.new.call
    history.succeed!
  end
end
