class VotesController < ApplicationController
  before_action :require_clerk_session!
  before_action :set_event

  def create
    Voting::CastVote.new.call(event: @event, user_id: clerk.user_id, choice: params[:choice])
    redirect_to events_path, notice: "Vote recorded."
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
