FactoryBot.define do
  factory :vote do
    event
    clerk_user_id { SecureRandom.uuid }
    choice { 'upvote' }
  end

  factory :upvote, parent: :vote do
    choice { 'upvote' }
  end

  factory :downvote, parent: :vote do
    choice { 'downvote' }
  end
end
