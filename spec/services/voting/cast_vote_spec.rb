require 'rails_helper'

RSpec.describe "Casting a vote through the command bus" do
  let(:event) { FactoryBot.create(:event) }
  let(:user_id) { SecureRandom.uuid }

  it 'records a first upvote and increments upvotes_count' do
    cast_vote('upvote')

    expect(event.reload).to have_attributes(upvotes_count: 1, downvotes_count: 0)
    expect(event.votes.find_by!(clerk_user_id: user_id).choice).to eq('upvote')
  end

  it 'records a first downvote and increments downvotes_count' do
    cast_vote('downvote')

    expect(event.reload).to have_attributes(upvotes_count: 0, downvotes_count: 1)
    expect(event.votes.find_by!(clerk_user_id: user_id).choice).to eq('downvote')
  end

  it 'moves the counts when the same user switches from upvote to downvote' do
    cast_vote('upvote')
    cast_vote('downvote')

    expect(event.reload).to have_attributes(upvotes_count: 0, downvotes_count: 1)
    expect(event.votes.where(clerk_user_id: user_id).pluck(:choice)).to eq([ 'downvote' ])
  end

  it 'retracts an upvote when the same user likes again' do
    cast_vote('upvote')
    cast_vote('upvote')

    expect(event.reload).to have_attributes(upvotes_count: 0, downvotes_count: 0)
    expect(event.votes.where(clerk_user_id: user_id)).to be_empty
    retracted = Rails.configuration.event_store.read.stream(Voting::Vote.stream_name(event.id, user_id)).to_a.last
    expect(retracted).to be_a(Voting::VoteRetracted)
    expect(retracted.data).to include(choice: 'upvote')
  end

  it 'retracts a downvote when the same user dislikes again' do
    cast_vote('downvote')
    cast_vote('downvote')

    expect(event.reload).to have_attributes(upvotes_count: 0, downvotes_count: 0)
    expect(event.votes.where(clerk_user_id: user_id)).to be_empty
  end

  def cast_vote(choice)
    Rails.configuration.command_bus.call(
      Voting::CastVote.new(event_id: event.id, user_id: user_id, choice: choice)
    )
  end
end
