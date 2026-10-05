class EventsController < ApplicationController
  def index
    @events = Event.includes(:votes).order(:starts_at)
    respond_to do |format|
      format.html
      format.json { render json: @events, status: :ok }
    end
  end
end
