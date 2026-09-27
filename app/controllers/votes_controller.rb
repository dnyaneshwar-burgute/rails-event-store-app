class VotesController < ApplicationController
  before_action :require_clerk_session!

  def create
    event = Event.find(params[:event_id])
    Voting::CastVote.new.call(event: event, user_id: clerk.user_id, choice: params[:choice])
    redirect_to events_path, notice: "Vote recorded."
  rescue Voting::CastVote::InvalidChoice
    redirect_to events_path, alert: "Choose like or dislike."
  end
end
