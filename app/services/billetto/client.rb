module Billetto
  class Client
    DEFAULT_BASE_URL = "https://billetto.dk/api/v3"
    PAGE_LIMIT = Rails.env.test? ? 5 : 100

    def initialize(api_keypair: ENV["BILLETTO_API_KEYPAIR"], base_url: ENV.fetch("BILLETTO_API_BASE", DEFAULT_BASE_URL), http: nil)
      @api_keypair = api_keypair
      @http = http || Faraday.new(url: base_url) do |connection|
        connection.options.timeout = 15
        connection.options.open_timeout = 5
      end
    end

    def list_public_events
      raise RequestError, "Billetto API key pair is not configured" if @api_keypair.blank?

      events = []
      query = { limit: PAGE_LIMIT }
      seen_cursors = []

      loop do
        payload = get_public_events(query)
        batch = payload["data"]
        raise RequestError, "Billetto response data was not a list" unless batch.is_a?(Array)

        events.concat(batch)
        cursor = next_cursor(payload, batch)
        break unless payload["has_more"] && cursor.present?
        break if seen_cursors.include?(cursor)

        seen_cursors << cursor
        query = { limit: PAGE_LIMIT, starting_after: cursor }
      end

      events
    end

    private

    def get_public_events(query)
      response = @http.get("public/events", query) do |request|
        request.headers["Api-Keypair"] = @api_keypair
        request.headers["Accept"] = "application/json"
      end

      raise RequestError, "Billetto request failed with status #{response.status}" unless response.success?

      parse_json(response.body)
    rescue RequestError
      raise
    rescue Faraday::Error => error
      raise RequestError, error.message
    end

    def parse_json(body)
      parsed = JSON.parse(body.to_s)
      raise RequestError, "Billetto response was not a JSON object" unless parsed.is_a?(Hash)

      parsed
    rescue JSON::ParserError
      raise RequestError, "Billetto response was not valid JSON"
    end

    def next_cursor(payload, batch)
      payload["starting_after"].presence ||
        payload["next_starting_after"].presence ||
        payload.dig("paging", "next").presence ||
        batch.last&.dig("id")&.to_s
    end
  end
end
