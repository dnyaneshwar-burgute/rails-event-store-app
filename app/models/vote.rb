# create_table "votes", force: :cascade do |t|
#   t.bigint "event_id", null: false
#   t.string "clerk_user_id", null: false
#   t.string "choice", null: false
#   t.datetime "created_at", null: false
#   t.datetime "updated_at", null: false
#   t.index ["event_id", "clerk_user_id"], name: "index_votes_on_event_id_and_clerk_user_id", unique: true
#   t.index ["event_id"], name: "index_votes_on_event_id"
# end
class Vote < ApplicationRecord
  CHOICES = %w[upvote downvote].freeze

  belongs_to :event

  validates :clerk_user_id, presence: true
  validates :choice, inclusion: { in: CHOICES }
  validates :clerk_user_id, uniqueness: { scope: :event_id }
end
