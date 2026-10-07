class VotesController < ApplicationController
  before_action :require_clerk_session!
  before_action :set_event

  def create
    retracting = @event.vote_for(clerk.user_id)&.choice == params[:choice]
    Voting::CastVote.new.call(event: @event, user_id: clerk.user_id, choice: params[:choice])
    redirect_to events_path, notice: retracting ? "Vote retracted." : "Vote recorded."
  rescue Voting::CastVote::InvalidChoice
    redirect_to events_path, alert: "Choose like or dislike."
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to events_path, alert: "Event not found."
  end
end
