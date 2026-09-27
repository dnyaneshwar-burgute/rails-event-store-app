class EventsController < ApplicationController
  def index
    @events = Event.order(:starts_at)
    respond_to do |format|
      format.html
      format.json { render json: @events, status: :ok }
    end
  end
end
