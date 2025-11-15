# scripts/smoke_sanity.rb
# Run with: bin/rails runner scripts/smoke_sanity.rb
# Verifies slugs, categories, citations, involvements, and relations.

puts "== Sanity Smoke Test =="

# 1. Soldier
s = Soldier.create!(first_name: "John", last_name: "Doe")
puts "Soldier slug: #{s.slug}"

# 2. Category
c = Category.create!(name: "Infantry", category_type: "topic")
s.categories << c
puts "Soldier categories: #{s.categories.pluck(:name).inspect}"

# 3. Source + Citation
src = Source.create!(title: "Regimental Records Vol. 1")
s.cite!(src, pages: "pp. 1012", note: "Listed as Private")
puts "Soldier sources: #{s.sources.pluck(:title).inspect}"
puts "Reverse lookup Source.cited_for(s): #{Source.cited_for(s).pluck(:title).inspect}"

# 4. Battle + Involvement
b = Battle.create!(name: "Battle of Gettysburg")
Involvement.create!(participant: s, involvable: b, role: "infantry", year: 1863)
puts "Soldier battles: #{s.battles.pluck(:name).inspect}"
puts "Battle soldiers: #{b.soldiers.pluck(:last_name).inspect}"

# 5. War + Relation
w = War.create!(name: "American Civil War")
Relation.create!(from: b, to: w, relation_type: "part_of")
puts "Battle wars: #{b.wars.pluck(:name).inspect}"
puts "War battles: #{w.battles.pluck(:name).inspect}"

puts "== Smoke Test Complete =="
