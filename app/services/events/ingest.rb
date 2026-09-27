module Events
  class Ingest
    CONTENT_ATTRIBUTES = %i[
      title description starts_at ends_at image_url url location_name city
    ].freeze

    Result = Struct.new(:created, :updated, :skipped, keyword_init: true)

    def initialize(client: Billetto::Client.new)
      @client = client
    end

    def call
      created = 0
      updated = 0
      skipped = []

      @client.each_public_events_batch do |batch|
        ActiveRecord::Base.transaction do
          batch.each do |item|
            attributes = attributes_for(item)
            if attributes.nil?
              skipped << skip_label(item)
              next
            end

            record = Event.find_or_initialize_by(billetto_id: attributes[:billetto_id])
            new_record = record.new_record?
            record.assign_attributes(attributes.slice(*CONTENT_ATTRIBUTES))
            unless record.valid?
              skipped << attributes[:billetto_id]
              next
            end

            record.save!
            new_record ? created += 1 : updated += 1
          end
        end
      end

      Result.new(created: created, updated: updated, skipped: skipped)
    end

    private

    def attributes_for(item)
      return unless item.is_a?(Hash)

      billetto_id = item["id"].presence
      title = item["title"].presence
      starts_at = parse_time(item["startdate"])
      return if billetto_id.blank? || title.blank? || starts_at.nil?

      {
        billetto_id: billetto_id.to_s,
        title: title,
        description: sanitize_description(item["description"]),
        starts_at: starts_at,
        ends_at: parse_time(item["enddate"]),
        image_url: item["image_link"].presence,
        url: item["url"].presence,
        location_name: item.dig("location", "location_name").presence,
        city: item.dig("location", "city").presence
      }
    end

    def sanitize_description(value)
      Rails::Html::FullSanitizer.new.sanitize(value.to_s).squish.presence
    end

    def parse_time(value)
      return if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end

    def skip_label(item)
      item.is_a?(Hash) ? (item["id"].presence || "unknown") : "unknown"
    end
  end
end
