# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# db/seeds.rb
# Category.ensure_medals_parent!

#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# puts "Seeding sample data..."

topic_cat = Category.find_or_create_by!(name: "Family History", category_type: "topic", slug: "family-history")
location_cat = Category.find_or_create_by!(name: "England", category_type: "location", slug: "england")

cem = Cemetery.find_or_create_by!(name: "Mount Auburn Cemetery", slug: "mount-auburn")

soldier = Soldier.find_or_create_by!(
  first_name: "John", middle_name: "H.", last_name: "Endicott",
  birthcity: "Plymouth", birthstate: "MA", birthcountry: "USA",
  deathcity: "Danvers", deathstate: "MA", deathcountry: "USA",
  cemetery: cem, slug: "john-h-endicott"
)

article = Article.find_or_create_by!(title: "The Endicott Pear Tree", slug: "endicott-pear-tree", body: "Oldest living cultivated fruit tree in North America.")

source = Source.find_or_create_by!(title: "NEHGS Register", repository: "New England Historic Genealogical Society", link_url: "https://www.americanancestors.org/", slug: "nehgs-register")

Citation.find_or_create_by!(source: source, citable: article, pages: "12-15", quote: "Endicott family lineage documented.", note: "Classic reference.")

article.categories << topic_cat unless article.categories.include?(topic_cat)
soldier.categories << location_cat unless soldier.categories.include?(location_cat)

war = War.find_or_create_by!(name: "American Revolution", slug: "american-revolution")
Involvement.find_or_create_by!(participant: soldier, involvable: war, role: "Captain", year: 1775, note: "Militia service")

puts "Seed complete."

#db/seeds.rb (append)
[
  { title: "UK Census 1861", common: true },
  { title: "Devon Parish Registers", common: true },
  { title: "Exeter & Plymouth Gazette", common: true }
].each do |attrs|
  Source.find_or_create_by!(title: attrs[:title]) { |s| s.assign_attributes(attrs) }
end

load Rails.root.join("db/seeds/common_sources.rb")

c = Category.wars.first || Category.create!(name: "War of 18125", category_type: "war", slug: "war-of-1812-5")
s = Soldier.first || Soldier.create!(first_name: "test5", last_name: "Person5")
s.category_ids |= [c.id]
s.save!
s.categories.pluck(:name)

c = Category.battles.first || Category.create!(name: "Bunker Hill", category_type: "battle", slug: "Bunker Hill")
s = Soldier.third || Soldier.create!(first_name: "test5", last_name: "Person5")
s.category_ids |= [c.id]
s.save!
s.categories.pluck(:name)

# db/seeds_soldiers.rb
# Generated 2025-09-10

# Quick seeds for Medals, Wars, and Battles so Soldier form dropdowns have data.

puts "Seeding medals, wars, and battles..."

medals = %w[Military\ Medal Victory\ Cross Bronze\ Star]
medals.each do |m|
  Medal.find_or_create_by!(name: m)
end

wars = ["World War I", "World War II", "Korean War"]
wars.each do |w|
  War.find_or_create_by!(name: w)
end

battles = ["Battle of the Somme", "Battle of Normandy", "Battle of Inchon"]
battles.each do |b|
  Battle.find_or_create_by!(name: b)
end

puts "Seeded: #{Medal.count} medals, #{War.count} wars, #{Battle.count} battles."

#  db/seeds.rb (append)
[
  { title: "Devon Parish Registers", repository: "DRO", common: true },
  { title: "UK Census 1861", repository: "TNA", common: true },
  { title: "Exeter & Plymouth Gazette", common: true }
].each do |attrs|
  Source.find_or_create_by!(title: attrs[:title]) { |s| s.assign_attributes(attrs) }
end

