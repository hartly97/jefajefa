# lib/tasks/data_backfill.rake
namespace :data do
  task backfill_soldier_burials: :environment do
    Soldier.where.not(cemetery_id: nil).find_each do |s|
      Involvement.where(
        involvable_type: "Cemetery", involvable_id: s.cemetery_id,
        participant_type: "Soldier", participant_id: s.id,
        role: "burial"
      ).first_or_create!
    end
  end
end
# run: bin/rails data:backfill_soldier_burials
