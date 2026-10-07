module Voting
  class OnCastVote
    def initialize(repository:)
      @repository = repository
    end

    def call(command)
      ApplicationRecord.transaction do
        repository.with_aggregate(
          Vote.new(command.event_id, command.user_id),
          Vote.stream_name(command.event_id, command.user_id)
        ) do |vote|
          vote.cast(command.choice)
        end
      end
    end

    private

    attr_reader :repository
  end
end
