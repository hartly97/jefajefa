📦 Download cumulative_bundle_with_full_reset.zip

What changed

db/seeds_reset.rb now deletes, in dependency-safe order:

Dependents first:

Citation.delete_all

Award.delete_all

Involvement.delete_all

(Optionally) any Relation rows where from_type or to_type is "Soldier"

Core records:

Soldier.delete_all

Lookup/reference tables:

Source.delete_all

Medal.delete_all

Battle.delete_all

War.delete_all

Cemetery.delete_all

Usage
bin/rails runner db/seeds_reset.rb
bin/rails db:seed


This gives you a clean slate for the entire soldier ecosystem (including sources, medals, wars, battles, cemeteries) and then reseeds both example soldiers + base lookups. If you also want it to clear Categories/Categorizations related to these, say the word and I’ll extend it.