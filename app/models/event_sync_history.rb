# create_table "event_sync_histories", force: :cascade do |t|
#   t.string "status", default: "draft", null: false
#   t.datetime "created_at", null: false
#   t.datetime "updated_at", null: false
#   t.index ["created_at"], name: "index_event_sync_histories_on_created_at"
#   t.index ["status"], name: "index_event_sync_histories_on_status"
# end
class EventSyncHistory < ApplicationRecord
  SYNC_COOLDOWN = 2.hours
  STATUSES = %w[draft sync_initiated sync_success sync_failed].freeze

  include AASM

  aasm column: :status do
    state :draft, initial: true
    state :sync_initiated
    state :sync_success
    state :sync_failed

    event :initiate_sync do
      transitions from: :draft, to: :sync_initiated
    end

    event :succeed do
      transitions from: :sync_initiated, to: :sync_success
    end

    event :fail_sync do
      transitions from: :sync_initiated, to: :sync_failed
    end
  end

  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  def self.latest
    recent.first
  end

  def self.sync_on_cooldown?
    ends_at = cooldown_ends_at
    ends_at.present? && ends_at.future?
  end

  def self.cooldown_ends_at
    last_sync = latest
    return if last_sync.nil?

    last_sync.created_at + SYNC_COOLDOWN
  end

  def self.record_sync_request
    transaction do
      acquire_sync_lock
      next if sync_on_cooldown?

      create!
    end
  end

  def status_label
    status.humanize
  end

  def self.acquire_sync_lock
    connection.execute(
      "SELECT pg_advisory_xact_lock(hashtext(#{connection.quote("event_sync_histories")}))"
    )
  end
  private_class_method :acquire_sync_lock
end
