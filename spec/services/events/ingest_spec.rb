require 'rails_helper'
require 'faraday/adapter/test'

RSpec.describe Events::Ingest do
  let(:billetto_id) { '323509ce-43fe-4a36-a037-c5ca924e3899' }
  let!(:existing_event) do
    FactoryBot.create(
      :event,
      billetto_id: billetto_id,
      title: 'Original title',
      description: 'Original description',
      upvotes_count: 4,
      downvotes_count: 2
    )
  end

  describe 'when the response is one page of PAGE_LIMIT records' do
    it 'creates the new events, updates the existing one, and skips the record without an id' do
      result, requests = ingest('public_events_5.json')

      expect(Billetto::Client::PAGE_LIMIT).to eq(5)
      expect(requests).to eq([ { 'limit' => '5' } ])
      expect(result).to have_attributes(created: 3, updated: 1, skipped: [ 'unknown' ])
      expect(Event.count).to eq(4)
      expect(Event.find_by(title: 'Untitled popup')).to be_nil
      expect(Event.where(billetto_id: billetto_id).count).to eq(1)

      expect_existing_event_updated
      expect(Event.find_by!(billetto_id: '11111111-1111-4111-8111-111111111111')).to have_attributes(
        title: 'Harbor Food Market',
        description: 'Street food by the water.',
        image_url: 'https://images.example.com/harbor.jpg',
        url: 'https://billetto.dk/e/harbor-food-market',
        location_name: 'Islands Brygge',
        city: 'Copenhagen',
        starts_at: Time.zone.parse('2026-10-03T11:00:00Z'),
        ends_at: Time.zone.parse('2026-10-03T16:00:00Z')
      )
    end
  end

  describe 'when the response has more records than PAGE_LIMIT' do
    it 'follows the cursor onto the next page' do
      result, requests = ingest('public_events_more_than_5.json')

      expect(requests).to eq([
        { 'limit' => '5' },
        { 'limit' => '5', 'starting_after' => '33333333-3333-4333-8333-333333333333' }
      ])
      expect(result).to have_attributes(created: 5, updated: 1, skipped: [ 'unknown' ])
      expect(Event.count).to eq(6)
      expect(Event.find_by(title: 'Untitled popup')).to be_nil
      expect(Event.where(billetto_id: billetto_id).count).to eq(1)

      expect_existing_event_updated
      expect(Event.find_by!(billetto_id: '44444444-4444-4444-8444-444444444444')).to have_attributes(
        title: 'Canal Concert',
        city: 'Copenhagen',
        starts_at: Time.zone.parse('2026-10-06T17:00:00Z')
      )
      expect(Event.find_by!(billetto_id: '55555555-5555-4555-8555-555555555555').title).to eq('Book Fair')
    end
  end

  def ingest(fixture_name)
    pages = JSON.parse(Rails.root.join('spec/fixtures/billetto', fixture_name).read)
    requests = []
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get('/public/events') do |env|
      requests << env[:params].transform_keys(&:to_s)
      page = pages.fetch(requests.length - 1)
      [ 200, { 'Content-Type' => 'application/json' }, JSON.generate(page) ]
    end

    http = Faraday.new(url: 'https://billetto.test') do |connection|
      connection.adapter :test, stubs
    end
    client = Billetto::Client.new(api_keypair: 'test-keypair', http: http)

    [ described_class.new(client: client).call, requests ]
  end

  def expect_existing_event_updated
    expect(existing_event.reload).to have_attributes(
      title: 'Copenhagen Jazz Night',
      description: 'Live jazz downtown.',
      image_url: 'https://images.example.com/jazz.jpg',
      url: 'https://billetto.dk/e/copenhagen-jazz-night',
      location_name: 'Vega',
      city: 'Copenhagen',
      starts_at: Time.zone.parse('2026-10-01T18:00:00Z'),
      ends_at: Time.zone.parse('2026-10-01T22:00:00Z'),
      upvotes_count: 4,
      downvotes_count: 2
    )
  end
end
