module Voting
  class CastVote
    class InvalidChoice < StandardError; end

    def call(event:, user_id:, choice:)
      raise InvalidChoice, "Choice must be upvote or downvote" unless Vote::CHOICES.include?(choice)
      raise ArgumentError, "User is required" if user_id.blank?

      current = event.votes.find_by(clerk_user_id: user_id)
      return event if current&.choice == choice

      domain_event = vote_event(choice).new(data: { event_id: event.id, user_id: user_id })
      stream_name = "Voting::Event$#{event.id}"

      ApplicationRecord.transaction do
        Rails.configuration.event_store.publish(
          domain_event,
          stream_name: stream_name,
          expected_version: :auto
        )
      end

      event.reload
    end

    private

    def vote_event(choice)
      choice == "upvote" ? EventUpvoted : EventDownvoted
    end
  end
end
