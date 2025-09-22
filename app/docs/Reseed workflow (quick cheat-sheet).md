Reseed workflow (quick cheat-sheet)

Reset the soldier ecosystem (clean slate)

bin/rails runner db/seeds_reset.rb


Run all seeds (lookups + example soldiers)

bin/rails db:seed


Smoke-test in console

# Should exist after seeding:
Soldier.count
Soldier.first.slug
Soldier.first.sources.pluck(:title)
Soldier.first.awards.includes(:medal).map { |a| [a.medal.name, a.year] }
Soldier.first.wars.pluck(:name)
Soldier.first.battles.pluck(:name)


Check routes + browse

bin/rails routes | grep soldiers