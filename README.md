# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version
  3.3.11

* Rails version
  8.1.4

* System dependencies

  git clone https://github.com/dnyaneshwar-burgute/rails-event-store-app.git

  cd rails-event-store-app

  bundle install

* Add a design-choices/assumptions

  As vote model is having the choices upvote for like and downvote for the dislike
  upvote: Like
  downvote: DisLike

* Configuration

  Change the env.example to .env and add your credentials in it

* Database creation

  rails db:setup

* Database initialization

  rails db:seed # (seed will generate the 3 basic events for testing purpose)

* How to run the test suite

  rspec spec/

* Services (job queues, cache servers, search engines, etc.)

  To get the real time data from the billetto run the task

  rails events:sync

* Deployment instructions

* ...
