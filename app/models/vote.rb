class Vote < ApplicationRecord
  CHOICES = %w[upvote downvote].freeze

  belongs_to :event

  validates :clerk_user_id, presence: true
  validates :choice, inclusion: { in: CHOICES }
  validates :clerk_user_id, uniqueness: { scope: :event_id }
end
