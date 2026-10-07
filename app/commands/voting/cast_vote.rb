module Voting
  class CastVote
    attr_reader :event_id, :user_id, :choice

    def initialize(event_id:, user_id:, choice:)
      @event_id = event_id
      @user_id = user_id
      @choice = choice
      freeze
    end
  end
end
