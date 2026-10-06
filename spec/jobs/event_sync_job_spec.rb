require "rails_helper"

RSpec.describe EventSyncJob, type: :job do
  let(:history) { FactoryBot.create(:event_sync_history) }
  let(:ingest) { instance_double(Events::Ingest) }

  before do
    allow(Events::Ingest).to receive(:new).and_return(ingest)
  end

  it "runs ingest and marks the history successful" do
    allow(ingest).to receive(:call).and_return(
      Events::Ingest::Result.new(created: 1, updated: 0, skipped: [])
    )

    described_class.perform_now(history.id)

    expect(ingest).to have_received(:call)
    expect(history.reload).to be_sync_success
  end

  it "marks the history failed and does not retry when ingest fails" do
    allow(ingest).to receive(:call).and_raise(Billetto::RequestError, "Billetto request failed")

    expect {
      described_class.perform_now(history.id)
    }.not_to have_enqueued_job(described_class)

    expect(history.reload).to be_sync_failed
  end
end
