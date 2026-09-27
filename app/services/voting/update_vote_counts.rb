module Voting
  class UpdateVoteCounts
    def call(domain_event)
      event = Event.find(domain_event.data.fetch(:event_id))
      user_id = domain_event.data.fetch(:user_id)
      choice = choice_for(domain_event)

      vote = event.votes.find_or_initialize_by(clerk_user_id: user_id)
      previous = vote.choice
      return if previous == choice

      ApplicationRecord.transaction do
        vote.update!(choice: choice)
        deltas = counter_deltas(previous, choice)
        Event.update_counters(event.id, **deltas) if deltas.any?
      end
    end

    private

    def choice_for(domain_event)
      case domain_event
      when EventUpvoted then "upvote"
      when EventDownvoted then "downvote"
      else
        raise ArgumentError, "Unsupported vote event: #{domain_event.class}"
      end
    end

    def counter_deltas(previous, choice)
      deltas = { upvotes_count: 0, downvotes_count: 0 }
      deltas[count_column(choice)] += 1
      deltas[count_column(previous)] -= 1 if previous.present?
      deltas.reject { |_column, delta| delta.zero? }
    end

    def count_column(choice)
      choice == "upvote" ? :upvotes_count : :downvotes_count
    end
  end
end
