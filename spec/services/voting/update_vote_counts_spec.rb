require "rails_helper"

RSpec.describe Voting::UpdateVoteCounts do
  subject(:update_vote_counts) { described_class.new }

  let(:event) { FactoryBot.create(:event) }
  let(:user_id) { SecureRandom.uuid }

  it "records a first upvote and increments upvotes_count" do
    update_vote_counts.call(upvoted(user_id))

    expect(event.reload).to have_attributes(upvotes_count: 1, downvotes_count: 0)
    expect(event.votes.find_by!(clerk_user_id: user_id).choice).to eq("upvote")
  end

  it "records a first downvote and increments downvotes_count" do
    update_vote_counts.call(downvoted(user_id))

    expect(event.reload).to have_attributes(upvotes_count: 0, downvotes_count: 1)
    expect(event.votes.find_by!(clerk_user_id: user_id).choice).to eq("downvote")
  end

  it "moves the counts when the same user switches from upvote to downvote" do
    update_vote_counts.call(upvoted(user_id))
    update_vote_counts.call(downvoted(user_id))

    expect(event.reload).to have_attributes(upvotes_count: 0, downvotes_count: 1)
    expect(event.votes.where(clerk_user_id: user_id).pluck(:choice)).to eq([ "downvote" ])
  end

  it "moves the counts when the same user switches from downvote to upvote" do
    update_vote_counts.call(downvoted(user_id))
    update_vote_counts.call(upvoted(user_id))

    expect(event.reload).to have_attributes(upvotes_count: 1, downvotes_count: 0)
    expect(event.votes.where(clerk_user_id: user_id).pluck(:choice)).to eq([ "upvote" ])
  end

  it "leaves the counts and the vote unchanged when the same choice is applied again" do
    update_vote_counts.call(upvoted(user_id))

    expect { update_vote_counts.call(upvoted(user_id)) }
      .not_to change { event.votes.where(clerk_user_id: user_id).count }

    expect(event.reload).to have_attributes(upvotes_count: 1, downvotes_count: 0)
    expect(event.votes.find_by!(clerk_user_id: user_id).choice).to eq("upvote")
  end

  it "counts votes from different users separately" do
    other_user_id = SecureRandom.uuid

    update_vote_counts.call(upvoted(user_id))
    update_vote_counts.call(downvoted(other_user_id))

    expect(event.reload).to have_attributes(upvotes_count: 1, downvotes_count: 1)
    expect(event.votes.pluck(:clerk_user_id, :choice)).to contain_exactly(
      [ user_id, "upvote" ],
      [ other_user_id, "downvote" ]
    )
  end

  it "raises when the event does not exist" do
    missing = Voting::EventUpvoted.new(data: { event_id: 0, user_id: user_id })

    expect { update_vote_counts.call(missing) }.to raise_error(ActiveRecord::RecordNotFound)
    expect(Vote.count).to eq(0)
  end

  it "raises when the domain event is not an upvote or a downvote" do
    other = RubyEventStore::Event.new(data: { event_id: event.id, user_id: user_id })

    expect { update_vote_counts.call(other) }
      .to raise_error(ArgumentError, "Unsupported vote event: RubyEventStore::Event")
    expect(event.reload).to have_attributes(upvotes_count: 0, downvotes_count: 0)
    expect(event.votes).to be_empty
  end

  def upvoted(clerk_user_id)
    Voting::EventUpvoted.new(data: { event_id: event.id, user_id: clerk_user_id })
  end

  def downvoted(clerk_user_id)
    Voting::EventDownvoted.new(data: { event_id: event.id, user_id: clerk_user_id })
  end
end
