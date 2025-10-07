# Quick association/sanity sweep
puts "== Soldiers (sample) =="
puts Soldier.limit(10).map(&:full_name)

if (s = Soldier.find_by(first_name: "Jane"))
  puts "\n== Jane Doe Categories =="
  p s.categories.pluck(:name, :category_type)
  puts "Citations:"
  s.citations.includes(:source).each { |c| puts "- #{c.source&.title} (#{c.pages}) - #{c.note}" }
  puts "Battles: #{s.battles.pluck(:name).inspect}"
  puts "Wars: #{s.wars.pluck(:name).inspect}"
  puts "Medals: #{s.medals.pluck(:name, :year).inspect}"
end

if (john = Soldier.find_by(last_name: "Endicott"))
  puts "\n== John Endicott Categories =="
  p john.categories.pluck(:name, :category_type)
end

puts "\n== Slug Check =="
[Category, Source, Soldier, Battle, War, Medal].each do |model|
  total   = model.count
  missing = model.where(slug: nil).count
  puts "#{model}: #{total} records, #{missing} missing slugs"
end

puts "\n== Backward Traversals =="
if (inf = Category.find_by(name: "Infantry"))
  puts "Infantry Soldiers: #{inf.soldiers.pluck(:full_name).inspect}"
end
if (medal = Medal.find_by(name: "Medal of Honor"))
  puts "Medal of Honor Soldiers: #{medal.soldiers.pluck(:full_name).inspect}"
end

puts "\nVerification complete."
