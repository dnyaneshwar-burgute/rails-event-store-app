require 'rails_helper'

RSpec.describe Voting::CastVote do
  subject(:cast_vote) { described_class.new }

  let(:event) { FactoryBot.create(:event) }
  let(:user_id) { SecureRandom.uuid }

  it 'records a first upvote and increments upvotes_count' do
    cast_vote.call(event: event, user_id: user_id, choice: 'upvote')

    expect(event.reload).to have_attributes(upvotes_count: 1, downvotes_count: 0)
    expect(event.votes.find_by!(clerk_user_id: user_id).choice).to eq('upvote')
  end

  it 'records a first downvote and increments downvotes_count' do
    cast_vote.call(event: event, user_id: user_id, choice: 'downvote')

    expect(event.reload).to have_attributes(upvotes_count: 0, downvotes_count: 1)
    expect(event.votes.find_by!(clerk_user_id: user_id).choice).to eq('downvote')
  end

  it 'moves the counts when the same user switches from upvote to downvote' do
    cast_vote.call(event: event, user_id: user_id, choice: 'upvote')
    cast_vote.call(event: event, user_id: user_id, choice: 'downvote')

    expect(event.reload).to have_attributes(upvotes_count: 0, downvotes_count: 1)
    expect(event.votes.where(clerk_user_id: user_id).pluck(:choice)).to eq([ 'downvote' ])
  end

  it 'leaves counts and the vote unchanged when the same choice is cast again' do
    cast_vote.call(event: event, user_id: user_id, choice: 'upvote')

    expect {
      cast_vote.call(event: event, user_id: user_id, choice: 'upvote')
    }.not_to change { Rails.configuration.event_store.read.count }

    expect(event.reload).to have_attributes(upvotes_count: 1, downvotes_count: 0)
    expect(event.votes.where(clerk_user_id: user_id).count).to eq(1)
  end
end
