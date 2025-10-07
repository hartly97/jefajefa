# db/seeds.rb
# Idempotent seeds for dev/test. Safe to run multiple times.
# bin/rails db:seed

require "securerandom"

def ensure_slug!(record, base)
  return if !record.respond_to?(:slug) || record.slug.present?
  record.slug = base.to_s.parameterize.presence || SecureRandom.hex(4)
  record.save!(validate: false)
end

def involvement!(soldier:, type:, inv:, role: nil, year: nil, note: nil)
  inv_rec = Involvement.find_or_initialize_by(
    participant_type: "Soldier",
    participant_id:   soldier.id,
    involvable_type:  type,
    involvable_id:    inv.id
  )
  inv_rec.role = role
  inv_rec.year = year
  inv_rec.note = note
  inv_rec.save!
  inv_rec
end

ActiveRecord::Base.transaction do
  puts "Seeding…"

  # --- Cemeteries ---
  evergreen = Cemetery.find_or_create_by!(name: "Evergreen Cemetery")
  oak_hill  = Cemetery.find_or_create_by!(name: "Oak Hill Cemetery")
  [evergreen, oak_hill].each { |c| ensure_slug!(c, c.name) }

  # --- Wars & Battles ---
  civil_war = War.find_or_create_by!(name: "American Civil War")
  rev_war   = War.find_or_create_by!(name: "American Revolutionary War")
  gettysburg = Battle.find_or_create_by!(name: "Battle of Gettysburg")
  bunker_hill = Battle.find_or_create_by!(name: "Battle of Bunker Hill")
  [civil_war, rev_war, gettysburg, bunker_hill].each { |r| ensure_slug!(r, r.name) }

  # Optional categories (flat; works even if you don’t use parent/children)
  cat_military = Category.find_or_create_by!(name: "Military")
  cat_civil    = Category.find_or_create_by!(name: "American Civil War")
  cat_rev      = Category.find_or_create_by!(name: "Revolutionary War")

  # --- Medals ---
  moh = Medal.find_or_create_by!(name: "Medal of Honor")
  ph  = Medal.find_or_create_by!(name: "Purple Heart")
  [moh, ph].each { |m| ensure_slug!(m, m.name) }

  # --- Soldiers ---
  john = Soldier.find_or_create_by!(first_name: "John", last_name: "Smith") do |s|
    s.cemetery = evergreen
    s.birth_date = Date.new(1840, 5, 2) rescue nil
    s.death_date = Date.new(1905, 11, 3) rescue nil
  end
  mary = Soldier.find_or_create_by!(first_name: "Mary", last_name: "Johnson") do |s|
    s.cemetery = oak_hill
    s.birth_date = Date.new(1757, 3, 14) rescue nil
    s.death_date = Date.new(1820, 8, 9) rescue nil
  end
  [john, mary].each { |s| ensure_slug!(s, [s.first_name, s.last_name].compact.join(" ")) }

  # Attach some categories (polymorphic Categorizable)
  [john, mary, civil_war, rev_war, gettysburg, bunker_hill].each do |rec|
    rec.categories << cat_military unless rec.categories.include?(cat_military) rescue nil
  end
  civil_war.categories << cat_civil unless civil_war.categories.include?(cat_civil) rescue nil
  rev_war.categories   << cat_rev   unless rev_war.categories.include?(cat_rev)   rescue nil

  # --- Awards (not medals) ---
  # john.awards.find_or_create_by!(name: "Community Service Award", year: 1870) do |a|
  #   a.country = "USA"
  #   a.note    = "Town recognition"
  # end

  # --- Awards (not medals) ---
award = john.awards.where(name: "Community Service Award", year: 1870).first_or_initialize
award.country = "USA"
award.note    = "Town recognition"

# If Award has a slug column, set it. If not, save without validations.
if award.respond_to?(:slug)
  award.slug = "community-service-award" if award.slug.blank?
  award.save!  # validates slug presence via Sluggable
else
  award.save!(validate: false) # no slug column → skip validations
end


  # --- SoldierMedals ---
  john.soldier_medals.find_or_create_by!(medal: moh) do |sm|
    sm.year = 1864
    sm.note = "Gallantry in action"
  end
  mary.soldier_medals.find_or_create_by!(medal: ph) do |sm|
    sm.year = 1777
    sm.note = "Wartime wound"
  end

  # --- Involvements (role/year/note) ---
  involvement!(soldier: john, type: "War",    inv: civil_war,   role: "Private, Infantry", year: 1863, note: "Mustered PA")
  involvement!(soldier: john, type: "Battle", inv: gettysburg,  role: "Color bearer",      year: 1863, note: "Day 2")
  involvement!(soldier: mary, type: "War",    inv: rev_war,     role: "Nurse",             year: 1776, note: "Boston area")
  # Cemetery involvement (optional; you already have belongs_to :cemetery)
  # involvement!(soldier: john, type: "Cemetery", inv: evergreen, role: "Interred", year: 1905)

  # --- Sources & Citations ---
  src1 = Source.find_or_create_by!(title: "Official Records of the War of the Rebellion") do |s|
    s.author = "U.S. War Department"
    s.year   = "1880–1901"
    s.url    = "https://example.org/or/"
    s.details = "Primary source compilation"
  end
  src2 = Source.find_or_create_by!(title: "Regimental History: 20th Maine") do |s|
    s.author = "J. Doe"
    s.year   = "1885"
    s.publisher = "Augusta Press"
  end
  [src1, src2].each { |s| ensure_slug!(s, s.title) }

  john.citations.find_or_create_by!(source: src1) do |c|
    c.pages = "12–13"
    c.quote = "Enlisted among the volunteers…"
    c.note  = "Company B muster roll"
  end

  gettysburg.citations.find_or_create_by!(source: src2) do |c|
    c.pages = "201"
    c.note  = "Order of battle"
  end

  # --- An Article ---
  article = Article.find_or_create_by!(title: "Local Heroes of the Civil War") do |a|
    a.body = "A brief account of notable service from our town."
    a.description = "Profiles of local participants"
    a.author = "Staff Writer"
    a.date = Date.new(2024,7,4) rescue nil
  end
  ensure_slug!(article, article.title)
  article.citations.find_or_create_by!(source: src1) { |c| c.pages = "55"; c.note = "Context" }

  # --- A Census + Entries (light) ---
  census = Census.find_or_create_by!(country: "USA", year: 1860, district: "Suffolk", subdistrict: "Boston", place: "Ward 6") do |c|
    c.folio = "12"
    c.page  = "3"
    c.external_image_url = "https://example.org/images/census1860_boston_ward6_p3.jpg"
  end
  ensure_slug!(census, [census.country, census.year, census.district, census.subdistrict, census.place].compact.join("-"))

  hid = "H001"
  CensusEntry.find_or_create_by!(census: census, householdid: hid, linenumber: 1, firstname: "John",  lastname: "Smith") do |e|
    e.age = "20"
    e.relationshiptohead = "Head"
    e.birthlikeplacetext = "Massachusetts"
    e.soldier = john
  end
  CensusEntry.find_or_create_by!(census: census, householdid: hid, linenumber: 2, firstname: "Mary", lastname: "Smith") do |e|
    e.age = "19"
    e.relationshiptohead = "Wife"
    e.birthlikeplacetext = "Massachusetts"
  end

  puts "Done."
  puts({
    soldiers: Soldier.count,
    wars: War.count,
    battles: Battle.count,
    cemeteries: Cemetery.count,
    medals: Medal.count,
    awards: Award.count,
    soldier_medals: SoldierMedal.count,
    involvements: Involvement.count,
    sources: Source.count,
    citations: Citation.count,
    categories: Category.count,
    censuses: Census.count,
    census_entries: CensusEntry.count,
    articles: Article.count
  }.map { |k,v| "#{k}=#{v}" }.join(" | "))
end
