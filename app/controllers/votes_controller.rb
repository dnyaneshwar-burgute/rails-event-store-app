class VotesController < ApplicationController
  before_action :require_clerk_session!
  before_action :set_event

  def create
    retracting = @event.vote_for(clerk.user_id)&.choice == params[:choice]
    Rails.configuration.command_bus.call(
      Voting::CastVote.new(event_id: @event.id, user_id: clerk.user_id, choice: params[:choice])
    )
    redirect_to events_path, notice: retracting ? "Vote retracted." : "Vote recorded."
  rescue Voting::Vote::InvalidChoice
    redirect_to events_path, alert: "Choose like or dislike."
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to events_path, alert: "Event not found."
  end
end
