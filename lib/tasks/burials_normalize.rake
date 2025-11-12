# lib/tasks/burials_normalize.rake
namespace :data do
  desc "Normalize burials: set participant_type='Soldier' where participant_id present; optionally link exact soldier matches in same cemetery"
  task normalize_burials: :environment do
    fixed = Burial.where(participant_type: [nil, "" ]).where.not(participant_id: nil)
                  .update_all(participant_type: "Soldier")
    puts "Set participant_type='Soldier' for #{fixed} existing rows with participant_id."

    # Optional: cautious name+cemetery linker (exact match only)
    linked = 0
    Burial.where(participant_id: nil).find_each do |b|
      next if b.first_name.blank? && b.last_name.blank?
      s = Soldier.where(cemetery_id: b.cemetery_id,
                        first_name: b.first_name,
                        last_name:  b.last_name).limit(2)
      next unless s.size == 1
      b.update(participant_type: "Soldier", participant_id: s.first.id)
      linked += 1
    end
    puts "Linked #{linked} civilian rows to a Soldier by exact name within same cemetery."
    puts "Done."
  end
end
