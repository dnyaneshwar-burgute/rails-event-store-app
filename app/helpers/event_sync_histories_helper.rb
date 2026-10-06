module EventSyncHistoriesHelper
  def sync_time(time)
    time.in_time_zone.strftime("%-d %B %Y, %H:%M")
  end
end
