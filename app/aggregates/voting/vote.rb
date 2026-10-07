module Voting
  class Vote
    include AggregateRoot

    class InvalidChoice < StandardError; end

    def initialize(event_id, user_id)
      @event_id = event_id
      @user_id = user_id
      @choice = nil
    end

    def cast(choice)
      raise ArgumentError, "User is required" if user_id.blank?
      raise InvalidChoice, "Choice must be upvote or downvote" unless ::Vote::CHOICES.include?(choice)

      apply(decision_for(choice))
    end

    def self.stream_name(event_id, user_id)
      "Voting::Vote$#{event_id}$#{user_id}"
    end

    on EventUpvoted do |_event|
      @choice = "upvote"
    end

    on EventDownvoted do |_event|
      @choice = "downvote"
    end

    on VoteRetracted do |_event|
      @choice = nil
    end

    private

    attr_reader :event_id, :user_id

    def decision_for(choice)
      if @choice == choice
        VoteRetracted.new(data: { event_id: event_id, user_id: user_id, choice: choice })
      elsif choice == "upvote"
        EventUpvoted.new(data: { event_id: event_id, user_id: user_id })
      else
        EventDownvoted.new(data: { event_id: event_id, user_id: user_id })
      end
    end
  end
end
