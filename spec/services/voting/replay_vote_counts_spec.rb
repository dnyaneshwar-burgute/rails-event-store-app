require "rails_helper"

RSpec.describe Voting::ReplayVoteCounts do
  subject(:replay_vote_counts) { described_class.new }

  let(:event) { FactoryBot.create(:event) }
  let(:user_id) { SecureRandom.uuid }

  it "restores drifted counts by replaying each voter's stream" do
    other_user_id = SecureRandom.uuid
    cast_vote(event, user_id, "upvote")
    cast_vote(event, other_user_id, "downvote")
    event.update!(upvotes_count: 9, downvotes_count: 4)

    replay_vote_counts.call(event.id)

    expect(event.reload).to have_attributes(upvotes_count: 1, downvotes_count: 1)
    expect(event.votes.pluck(:clerk_user_id, :choice)).to contain_exactly(
      [ user_id, "upvote" ],
      [ other_user_id, "downvote" ]
    )
  end

  it "keeps only the latest choice when a user switches" do
    cast_vote(event, user_id, "upvote")
    cast_vote(event, user_id, "downvote")
    event.update!(upvotes_count: 3, downvotes_count: 3)

    replay_vote_counts.call(event.id)

    expect(event.reload).to have_attributes(upvotes_count: 0, downvotes_count: 1)
  end

  it "drops a user after their vote is retracted" do
    cast_vote(event, user_id, "upvote")
    cast_vote(event, user_id, "upvote")
    event.update!(upvotes_count: 2, downvotes_count: 2)

    replay_vote_counts.call(event.id)

    expect(event.reload).to have_attributes(upvotes_count: 0, downvotes_count: 0)
  end

  it "counts the stream when the vote rows are missing" do
    cast_vote(event, user_id, "upvote")
    event.votes.delete_all
    event.update!(upvotes_count: 0, downvotes_count: 7)

    replay_vote_counts.call(event.id)

    expect(event.reload).to have_attributes(upvotes_count: 1, downvotes_count: 0)
    expect(event.votes).to be_empty
  end

  it "sets both counts to zero when the event has no vote stream" do
    event.update!(upvotes_count: 2, downvotes_count: 1)

    replay_vote_counts.call(event.id)

    expect(event.reload).to have_attributes(upvotes_count: 0, downvotes_count: 0)
  end

  it "updates only the given event" do
    other = FactoryBot.create(:event, upvotes_count: 4, downvotes_count: 5)
    cast_vote(event, user_id, "upvote")
    event.update!(upvotes_count: 0, downvotes_count: 8)

    replay_vote_counts.call(event.id)

    expect(event.reload).to have_attributes(upvotes_count: 1, downvotes_count: 0)
    expect(other.reload).to have_attributes(upvotes_count: 4, downvotes_count: 5)
  end

  it "raises EventNotFound when the event id does not exist" do
    expect { replay_vote_counts.call(0) }
      .to raise_error(described_class::EventNotFound, "Event 0 not found")
  end

  def cast_vote(record, clerk_user_id, choice)
    Rails.configuration.command_bus.call(
      Voting::CastVote.new(event_id: record.id, user_id: clerk_user_id, choice: choice)
    )
  end
end
