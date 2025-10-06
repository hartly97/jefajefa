# db/seeds.rb
# Idempotent seeds for Endicott bundles.
# Safe to run multiple times.
require "date"

# parse an ISO string to Date, or nil if bad
def d(iso)
  Date.iso8601(iso)
rescue ArgumentError, TypeError
  nil
end


puts "== Seeding Endicott sample data =="

def attr?(record, name)
  record.respond_to?(:has_attribute?) ? record.has_attribute?(name) : false
end

def assign_if(record, attrs)
  attrs.each do |k, v|
    record[k] = v if attr?(record, k)
  end
end

# -- Categories (optional) --------------------------------------------------
if Object.const_defined?("Category")
  %w[Military Genealogy Newspaper].each do |name|
    Category.where(name: name).first_or_create!
  end
  puts "Categories: #{Category.count} total"
else
  puts "Category model not found — skipping category seeds"
end

# -- Sources ----------------------------------------------------------------
sources_data = [
  { title: "Parish Registers of St. Mary's", author: "J. Clarke", year: "1849", common: true },
  { title: "The National Archives — Census Collection", publisher: "TNA", url: "https://nationalarchives.gov.uk", common: true },
  { title: "Regimental Muster Roll, 1863", publisher: "War Office" },
  { title: "Endicott Daily Herald", year: "1902", publisher: "EDH" },
  { title: "Family Bible of the Hartley Family", details: "Notes on births & deaths" }
]

sources = sources_data.map do |attrs|
  Source.where(title: attrs[:title]).first_or_initialize.tap do |r|
    assign_if(r, attrs)
    r.save!
  end
end
puts "Sources: #{Source.count} total"

# Tag a couple of sources if Category exists
if Object.const_defined?("Category") && Object.const_defined?("Categorization")
  military = Category.find_by(name: "Military")
  news     = Category.find_by(name: "Newspaper")
  if military
    [sources[2]].each { |s| s.categories << military unless s.categories.include?(military) }
  end
  if news
    [sources[3]].each { |s| s.categories << news unless s.categories.include?(news) }
  end
end

# -- Cemetery ---------------------------------------------------------------
cemetery = if Object.const_defined?("Cemetery")
  Cemetery.where(name: "Oakwood Cemetery").first_or_initialize.tap do |c|
    assign_if(c, {
      city: "Endicott",
      county: "Broome County",
      state: "New York",
      country: "USA",
      description: "Historic cemetery with Civil War burials."
    })
    c.save!
  end
else
  nil
end
puts "Cemetery: #{cemetery&.id ? "created/updated" : "skipped"}"

# -- Soldiers ---------------------------------------------------------------
soldier = if Object.const_defined?("Soldier")
  Soldier.where(first_name: "Thomas", last_name: "Hartley").first_or_initialize.tap do |s|
    assign_if(s, {
      branch_of_service: "Army",
      unit: "54th Regiment",
      first_enlisted_start_date: Date.new(1863,5,1) rescue "1863-05-01",
      first_enlisted_end_date: Date.new(1865,6,1) rescue "1865-06-01",
      birth_day: Date.new(1845,2,3) rescue "1845-02-03",
      birthplace: "Yorkshire, England",
      death_day: Date.new(1912,8,12) rescue "1912-08-12",
      deathplace: "Endicott, NY"
    })
    s.cemetery = cemetery if s.respond_to?(:cemetery=) && cemetery
    s.save!
  end
else
  nil
end
puts "Soldier: #{soldier&.id ? "created/updated" : "skipped"}"

# -- Articles ---------------------------------------------------------------
article = if Object.const_defined?("Article")
  Article.where(title: "Early Endicott Settlers").first_or_initialize.tap do |a|
    assign_if(a, {
      body: "A brief history of the families who established the town in the late 19th century."
    })
    a.save!
  end
else
  nil
end
puts "Article: #{article&.id ? "created/updated" : "skipped"}"

# -- Census + Entries -------------------------------------------------------
census = if Object.const_defined?("Census")
  Census.where(country: "UK", year: 1851, district: "Middlesex").first_or_initialize.tap do |c|
    assign_if(c, {
      subdistrict: "Kensington",
      place: "Brompton",
      piece: "HO107/1469",
      folio: "23",
      page: "7",
      external_image_url: "https://photos.smugmug.com/sample-census/photo.jpg",
      external_image_caption: "1851 Census page sample",
      external_image_credit: "via SmugMug"
    })
    c.save!
  end
else
  nil
end

if census && Object.const_defined?("CensusEntry")
  # Clear any existing demo entries for this census (optional & safe for demo)
  CensusEntry.where(census_id: census.id).delete_all

  rows = [
    { householdid: "100", linenumber: 1, firstname: "George", lastname: "Fowler", age: 42, relationshiptohead: "Head",   birthlikeplacetext: "Middlesex" },
    { householdid: "100", linenumber: 2, firstname: "Anne",   lastname: "Fowler", age: 40, relationshiptohead: "Wife",   birthlikeplacetext: "Surrey" },
    { householdid: "100", linenumber: 3, firstname: "Mary",   lastname: "Fowler", age: 12, relationshiptohead: "Daughter", birthlikeplacetext: "Middlesex" },
    { householdid: "100", linenumber: 4, firstname: "John",   lastname: "Fowler", age: 9,  relationshiptohead: "Son",    birthlikeplacetext: "Middlesex" }
  ]
  rows.each do |r|
    CensusEntry.create!(r.merge(census_id: census.id))
  end
  puts "Census + entries: created (#{rows.size} entries)"
else
  puts "Census: #{census ? "created" : "skipped"}; entries skipped"
end

# -- Citations (polymorphic) -----------------------------------------------
def cite!(citable, src, attrs = {})
  return unless citable && src
  citable.citations.where(source_id: src.id, pages: attrs[:pages]).first_or_initialize.tap do |cit|
    attrs.each { |k,v| cit[k] = v if cit.has_attribute?(k) rescue nil }
    cit.source = src
    cit.save!
  end
end

s1, s2, s3, s4, s5 = sources

cite!(soldier, s3, pages: "14", note: "Listed on muster roll")
cite!(soldier, s4, pages: "1",  note: "Obituary mention in local paper")

cite!(article, s1, pages: "112–113", note: "Register entries for key families")
cite!(article, s4, pages: "A3",      note: "Newspaper article reference")

cite!(census,  s2, pages: "folio 23 / page 7", locator: "HO107/1469")
cite!(census,  s5, note: "Family Bible confirms names/ages")

puts "Citations seeded (where applicable)."
puts "== Done =="
