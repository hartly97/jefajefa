
# scripts/smoke_sanity_cleanup.rb
# Removes the records created by scripts/smoke_sanity.rb
# Usage:
#   bin/rails runner scripts/smoke_sanity_cleanup.rb

Rails.application.eager_load!
def say(h); puts "\n=== #{h} ==="; end

say "Locating test records"

soldier  = defined?(Soldier)  ? Soldier.find_by(slug: "john-doe") : nil
category = defined?(Category) ? Category.find_by(slug: "infantry") : nil
source   = defined?(Source)   ? Source.find_by(slug: "regimental-records-vol-1") || Source.find_by(title: "Regimental Records Vol. 1") : nil
battle   = defined?(Battle)   ? Battle.find_by(slug: "battle-of-gettysburg") : nil
war      = defined?(War)      ? War.find_by(slug: "american-civil-war") : nil

say "Cleaning citations for soldier"
if soldier && defined?(Citation)
  Citation.where(citable: soldier).delete_all
end

say "Cleaning involvements and relations"
if defined?(Involvement)
  Involvement.where(participant: soldier).delete_all if soldier
  Involvement.where(involvable: battle).delete_all if battle
end
if defined?(Relation)
  Relation.where(from: battle).delete_all if battle
  Relation.where(to: war).delete_all if war
end

say "Unlink categorizations"
if soldier && defined?(Categorization)
  Categorization.where(categorizable: soldier).delete_all
end

say "Destroy core records (soldier, cat, source, battle, war)"
[source, category, battle, war, soldier].compact.each do |rec|
  begin
    rec.destroy!
    puts "Destroyed #{rec.class}##{rec.id}"
  rescue => e
    puts "Skip #{rec.class}: #{e.class} - #{e.message}"
  end
end

say "Done"
