# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
event1 = Event.create(
  billetto_id: SecureRandom.uuid,
  title: "Event One",
  description: "This is the description for the event one",
  starts_at: Time.current + 1.day,
  ends_at: (Time.current + 5.day),
  location_name: "Baner",
  city: "Pune"
)

event2 = Event.create(
  billetto_id: SecureRandom.uuid,
  title: "Event Two",
  description: "This is the description for the event two",
  starts_at: Time.current,
  ends_at: (Time.current + 6.day),
  location_name: "Viman Nagar",
  city: "Pune"
)

event3 = Event.create(
  billetto_id: SecureRandom.uuid,
  title: "Event Three",
  description: "This is the description for the event three",
  starts_at: Time.current + 1.day,
  location_name: "MG Road & Brigade Road",
  city: "Banglore"
)

event4 = Event.create(
  billetto_id: SecureRandom.uuid,
  title: "Event Four",
  description: "This is the description for the event Four",
  starts_at: Time.current,
  ends_at: (Time.current + 6.day),
  location_name: "Jayanagar & Malleshwaram",
  city: "Pune"
)

