module Voting
  class ReplayVoteCounts
    class EventNotFound < StandardError; end

    def initialize(event_store: Rails.configuration.event_store)
      @event_store = event_store
    end

    def call(event_id)
      event = ::Event.find_by(id: event_id)
      raise EventNotFound, "Event #{event_id} not found" if event.nil?

      choices = {}

      stream_names_for(event_id).each do |stream_name|
        event_store.read.stream(stream_name).each do |domain_event|
          choices[domain_event.data.fetch(:user_id)] = choice_for(domain_event)
        end
      end

      event.update!(
        upvotes_count: choices.values.count("upvote"),
        downvotes_count: choices.values.count("downvote")
      )
    end

    private

    attr_reader :event_store

    def stream_names_for(event_id)
      prefix = Vote.stream_name(event_id, "")
      pattern = "#{ApplicationRecord.sanitize_sql_like(prefix)}%"

      ApplicationRecord.with_connection do |connection|
        connection.select_values(
          ApplicationRecord.sanitize_sql_array([
            "SELECT DISTINCT stream FROM event_store_events_in_streams WHERE stream LIKE ?",
            pattern
          ])
        )
      end
    end

    def choice_for(domain_event)
      case domain_event
      when EventUpvoted then "upvote"
      when EventDownvoted then "downvote"
      when VoteRetracted then nil
      else
        raise ArgumentError, "Unsupported vote event: #{domain_event.class}"
      end
    end
  end
end
