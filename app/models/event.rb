# create_table :events do |t|
#   t.string :billetto_id, null: false
#   t.string :title, null: false
#   t.string :description
#   t.datetime :starts_at, null: false
#   t.datetime :ends_at
#   t.string :image_url
#   t.string :url
#   t.string :location_name
#   t.string :city
#   t.integer :upvotes_count, null: false, default: 0
#   t.integer :downvotes_count, null: false, default: 0

#   t.timestamps
# end
class Event < ApplicationRecord
  # Relationships
  has_many :votes, dependent: :destroy

  # Validations
  validates :billetto_id, presence: { message: "^Billetto Id should be present" }
  validates :title, presence: { message: "^Title should be present" }
  validates :starts_at, presence: { message: "^Starts At should be present" }
  validates :billetto_id, uniqueness: { message: "^Billetto Id is already taken" }
  validates :upvotes_count, :downvotes_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Public Methods
  def brief_description
    description.presence || "No description"
  end

  def vote_for(user_id)
    return if user_id.blank?

    if votes.loaded?
      votes.find { |vote| vote.clerk_user_id == user_id }
    else
      votes.find_by(clerk_user_id: user_id)
    end
  end
end
