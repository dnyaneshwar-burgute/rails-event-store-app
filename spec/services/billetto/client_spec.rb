require "rails_helper"
require "faraday/adapter/test"

RSpec.describe Billetto::Client do
  describe "PAGE_LIMIT" do
    it "requests five events per page in the test environment" do
      expect(described_class::PAGE_LIMIT).to eq(5)
    end
  end

  describe "#each_public_events_batch" do
    it "raises before calling the API when the key pair is missing" do
      client, requests = build_client(api_keypair: nil, responses: [])

      expect { client.each_public_events_batch { nil } }
        .to raise_error(Billetto::RequestError, "Billetto API key pair is not configured")
      expect(requests).to be_empty
    end

    it "raises before calling the API when the key pair is blank" do
      client, requests = build_client(api_keypair: "  ", responses: [])

      expect { client.each_public_events_batch { nil } }
        .to raise_error(Billetto::RequestError, "Billetto API key pair is not configured")
      expect(requests).to be_empty
    end

    it "sends the key pair and accept headers and yields one page when there is no next page" do
      events = [ { "id" => "event-1", "title" => "Jazz Night" } ]
      client, requests = build_client(responses: [
        page(data: events, has_more: false)
      ])

      batches = []
      client.each_public_events_batch { |batch| batches << batch }

      expect(batches).to eq([ events ])
      expect(requests.size).to eq(1)
      expect(requests.first[:params].transform_keys(&:to_s)).to eq("limit" => "5")
      expect(requests.first.request_headers["Api-Keypair"]).to eq("test-keypair")
      expect(requests.first.request_headers["Accept"]).to eq("application/json")
    end

    it "returns an enumerator that yields the same batches when no block is given" do
      events = [ { "id" => "event-1" } ]
      client, _requests = build_client(responses: [
        page(data: events, has_more: false)
      ])

      enum = client.each_public_events_batch

      expect(enum).to be_a(Enumerator)
      expect(enum.to_a).to eq([ events ])
    end

    it "follows the after cursor from next_url onto the next page" do
      first_page = [ { "id" => "event-1" } ]
      second_page = [ { "id" => "event-2" } ]
      client, requests = build_client(responses: [
        page(
          data: first_page,
          has_more: true,
          next_url: "https://billetto.test/api/v3/public/events?limit=5&after=cursor-1"
        ),
        page(data: second_page, has_more: false)
      ])

      expect(client.each_public_events_batch.to_a).to eq([ first_page, second_page ])
      expect(requests.map { |env| env[:params].transform_keys(&:to_s) }).to eq([
        { "limit" => "5" },
        { "limit" => "5", "after" => "cursor-1" }
      ])
    end

    it "stops when the next page repeats a cursor it has already followed" do
      client, requests = build_client(responses: [
        page(data: [ { "id" => "event-1" } ], has_more: true, next_url: "https://billetto.test/events?after=cursor-1"),
        page(data: [ { "id" => "event-2" } ], has_more: true, next_url: "https://billetto.test/events?after=cursor-1"),
        page(data: [ { "id" => "event-3" } ], has_more: false)
      ])

      expect(client.each_public_events_batch.to_a.map { |batch| batch.map { |event| event["id"] } })
        .to eq([ [ "event-1" ], [ "event-2" ] ])
      expect(requests.size).to eq(2)
    end

    it "raises when the payload is not a list" do
      client, _requests = build_client(responses: [
        [ 200, json_headers, { "object" => "event", "data" => [] }.to_json ]
      ])

      expect { client.each_public_events_batch.to_a }
        .to raise_error(Billetto::RequestError, "Billetto response was not a list")
    end

    it "raises when the list data is not an array" do
      client, _requests = build_client(responses: [
        [ 200, json_headers, { "object" => "list", "data" => { "id" => "event-1" } }.to_json ]
      ])

      expect { client.each_public_events_batch.to_a }
        .to raise_error(Billetto::RequestError, "Billetto response data was not a list")
    end

    it "raises with the HTTP status when the request fails" do
      client, _requests = build_client(responses: [
        [ 401, json_headers, { "error" => "unauthorized" }.to_json ]
      ])

      expect { client.each_public_events_batch.to_a }
        .to raise_error(Billetto::RequestError, "Billetto request failed with status 401")
    end

    it "wraps a Faraday failure as a request error" do
      client, _requests = build_client(responses: [
        ->(*) { raise Faraday::TimeoutError, "execution expired" }
      ])

      expect { client.each_public_events_batch.to_a }
        .to raise_error(Billetto::RequestError, "execution expired")
    end

    it "raises when the body is not valid JSON" do
      client, _requests = build_client(responses: [
        [ 200, json_headers, "not-json" ]
      ])

      expect { client.each_public_events_batch.to_a }
        .to raise_error(Billetto::RequestError, "Billetto response was not valid JSON")
    end

    it "raises when the JSON body is not an object" do
      client, _requests = build_client(responses: [
        [ 200, json_headers, [ { "id" => "event-1" } ].to_json ]
      ])

      expect { client.each_public_events_batch.to_a }
        .to raise_error(Billetto::RequestError, "Billetto response was not a JSON object")
    end

    it "raises when another page is promised without a next_url" do
      client, _requests = build_client(responses: [
        page(data: [], has_more: true, next_url: nil)
      ])

      expect { client.each_public_events_batch.to_a }
        .to raise_error(Billetto::RequestError, "Billetto response was missing next_url")
    end

    it "raises when next_url has no after cursor" do
      client, _requests = build_client(responses: [
        page(data: [], has_more: true, next_url: "https://billetto.test/events?limit=5")
      ])

      expect { client.each_public_events_batch.to_a }
        .to raise_error(Billetto::RequestError, "Billetto next_url was missing an after cursor")
    end

    it "raises when next_url is not a valid URI" do
      client, _requests = build_client(responses: [
        page(data: [], has_more: true, next_url: "http://exa mple.com/events?after=cursor-1")
      ])

      expect { client.each_public_events_batch.to_a }
        .to raise_error(Billetto::RequestError, "Billetto next_url was invalid")
    end
  end

  def build_client(responses:, api_keypair: "test-keypair")
    requests = []
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get("/public/events") do |env|
      requests << env
      response = responses.fetch(requests.length - 1)
      response.respond_to?(:call) ? response.call(env) : response
    end

    http = Faraday.new(url: "https://billetto.test") do |connection|
      connection.adapter :test, stubs
    end

    [ described_class.new(api_keypair: api_keypair, http: http), requests ]
  end

  def page(data:, has_more:, next_url: nil)
    body = { "object" => "list", "data" => data, "has_more" => has_more }
    body["next_url"] = next_url unless next_url.nil?
    [ 200, json_headers, body.to_json ]
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end
end
