namespace :events do
  desc "Fetch public events from the Billetto API and upsert them"
  task sync: :environment do
    result = Events::Ingest.new.call
    puts "Created #{result.created}, updated #{result.updated}, skipped #{result.skipped.size}"
    result.skipped.each { |identifier| puts "Skipped #{identifier}" }
  end
end
