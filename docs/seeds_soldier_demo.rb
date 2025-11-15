# Run with:
#   bin/rails runner db/seeds_soldier_demo.rb

ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.logger.level = Logger::INFO

def say(msg) = puts "\n==> #{msg}"

say "Ensuring base records exist (Medal, Cemetery, Source)..."

medal = Medal.find_or_create_by!(name: "Purple Heart") { |m| m.slug = "purple-heart" }
cemetery = (defined?(Cemetery) ? (Cemetery.first || Cemetery.create!(name: "Mount Auburn Cemetery", slug: "mount-auburn-cemetery")) : nil)
source = Source.find_or_create_by!(title: "Boston Gazette") { |s| s.year = "1750" }

say "Creating a demo Soldier with nested Award, Medal, and Citation..."

soldier = Soldier.create!(
  first_name: "Test",
  last_name:  "User",
  unit: "Infantry",
  branch_of_service: "Army",
  cemetery: cemetery
)

soldier.awards.create!(name: "Community Service", country: "USA", year: 1950, note: "Local recognition")
soldier.soldier_medals.create!(medal: medal, year: 1945, note: "Wartime commendation")
soldier.citations.create!(source: source, pages: "12–13", note: "Newspaper blurb")

say "Done."
say "Soldier:  #{soldier.id} — #{[soldier.first_name, soldier.last_name].compact.join(' ')}"
say "Awards:   #{soldier.awards.count}"
say "Medals:   #{soldier.medals.count} (via SoldierMedals: #{soldier.soldier_medals.count})"
say "Citations #{soldier.citations.count} (Sources: #{soldier.sources.count})"
