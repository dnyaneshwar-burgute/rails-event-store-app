require "rails_helper"

RSpec.describe Voting::Vote do
  let(:event_id) { 42 }
  let(:user_id) { SecureRandom.uuid }

  it "emits an upvote when a vote is cast for the first time" do
    vote = described_class.new(event_id, user_id)

    vote.cast("upvote")

    expect(vote.unpublished_events.to_a).to contain_exactly(
      an_instance_of(Voting::EventUpvoted).and(have_attributes(data: { event_id: event_id, user_id: user_id }))
    )
  end

  it "emits a downvote when a vote is cast for the first time" do
    vote = described_class.new(event_id, user_id)

    vote.cast("downvote")

    expect(vote.unpublished_events.to_a).to contain_exactly(
      an_instance_of(Voting::EventDownvoted).and(have_attributes(data: { event_id: event_id, user_id: user_id }))
    )
  end

  it "emits a downvote when an existing upvote changes" do
    vote = vote_with(Voting::EventUpvoted.new(data: { event_id: event_id, user_id: user_id }))

    vote.cast("downvote")

    expect(vote.unpublished_events.map(&:class)).to eq([ Voting::EventDownvoted ])
  end

  it "emits a retraction when the same choice is cast again" do
    vote = vote_with(Voting::EventUpvoted.new(data: { event_id: event_id, user_id: user_id }))

    vote.cast("upvote")

    retracted = vote.unpublished_events.to_a.last
    expect(retracted).to be_a(Voting::VoteRetracted)
    expect(retracted.data).to include(event_id: event_id, user_id: user_id, choice: "upvote")
  end

  it "emits a new upvote after a retraction" do
    vote = vote_with(
      Voting::EventUpvoted.new(data: { event_id: event_id, user_id: user_id }),
      Voting::VoteRetracted.new(data: { event_id: event_id, user_id: user_id, choice: "upvote" })
    )

    vote.cast("upvote")

    expect(vote.unpublished_events.map(&:class)).to eq([ Voting::EventUpvoted ])
  end

  it "rejects a choice outside upvote and downvote" do
    vote = described_class.new(event_id, user_id)

    expect { vote.cast("maybe") }.to raise_error(described_class::InvalidChoice)
    expect(vote.unpublished_events.to_a).to be_empty
  end

  it "rejects a vote without a user" do
    vote = described_class.new(event_id, "")

    expect { vote.cast("upvote") }.to raise_error(ArgumentError, "User is required")
    expect(vote.unpublished_events.to_a).to be_empty
  end

  def vote_with(*events)
    vote = described_class.new(event_id, user_id)
    events.each { |event| vote.apply(event) }
    vote.version = events.size - 1
    vote
  end
end
