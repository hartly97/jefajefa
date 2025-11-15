# db/seeds/categories.rb
def ensure_category(name, type)
  cat = Category.find_or_initialize_by(name: name, category_type: type)
  cat.slug ||= name.parameterize
  cat.save! if cat.changed?
  cat
end

SEED_CATEGORIES = {
  # used by Soldier form
  "soldier" => %w[Infantry Cavalry Artillery Navy Marines Home\ Guard Militia Unknown],

  # used by Burials form
  "burial"  => %w[Veteran\ Grave Family\ Plot Unmarked Government\ Marker Reinterred Unknown],

  # common “taxonomy” types you’ve mentioned
  "war"     => ["American Revolution", "War of 1812", "Civil War", "World War I", "World War II"],
  "battle"  => ["Bunker Hill", "Saratoga", "Yorktown", "Gettysburg"],
  "medal"   => ["Medal of Honor", "Purple Heart", "Good Conduct Medal"],
  "article" => ["Biography", "Local History", "Methodology"],
  "award"   => ["Community Service", "Lifetime Achievement"],
  "census"  => ["1850 US Census", "1860 US Census", "1870 US Census"],
  "cemetery"=> ["Historic", "Town", "Private"]
}.freeze

SEED_CATEGORIES.each do |type, names|
  names.each { |n| ensure_category(n, type) }
end

puts "Seeded categories:"
puts Category.order(:category_type, :name).pluck(:category_type, :name).map { |t, n| " - #{t}: #{n}" }
