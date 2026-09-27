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

    def each_public_events_batch
      raise RequestError, "Billetto API key pair is not configured" if @api_keypair.blank?

      return enum_for(:each_public_events_batch) unless block_given?

      query = { limit: PAGE_LIMIT }
      seen_cursors = []

      loop do
        payload = get_public_events(query)
        raise RequestError, "Billetto response was not a list" unless payload["object"] == "list"

        batch = payload["data"]
        raise RequestError, "Billetto response data was not a list" unless batch.is_a?(Array)

        yield batch

        break unless payload["has_more"]

        cursor = after_cursor(payload["next_url"])
        break if seen_cursors.include?(cursor)

        seen_cursors << cursor
        query = { limit: PAGE_LIMIT, after: cursor }
      end
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

    def after_cursor(next_url)
      raise RequestError, "Billetto response was missing next_url" if next_url.blank?

      cursor = URI.decode_www_form(URI.parse(next_url).query.to_s).to_h["after"].presence
      raise RequestError, "Billetto next_url was missing an after cursor" if cursor.blank?

      cursor
    rescue URI::InvalidURIError
      raise RequestError, "Billetto next_url was invalid"
    end
  end
end
