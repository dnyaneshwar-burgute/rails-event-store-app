FactoryBot.define do
  factory :event do
    billetto_id { SecureRandom.uuid }
    sequence(:title) { |n| "event_title_#{n}" }
    sequence(:description) { |n| "event_description_#{n}" }
    starts_at { Time.current }
  end
end
