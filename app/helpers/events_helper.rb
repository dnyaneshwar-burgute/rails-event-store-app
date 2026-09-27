module EventsHelper
  def event_location(event)
    [ event.location_name, event.city ].compact_blank.join(", ")
  end
end
