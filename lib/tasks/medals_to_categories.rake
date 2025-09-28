namespace :data do
  desc "Backfill: attach a Category per medal to each Soldier"
  task medals_to_categories: :environment do
    # Optionally create a parent category for organization
    parent = Category.find_or_create_by!(name: "Medals")

    Medal.includes(:soldiers).find_each do |medal|
      cat = Category.find_or_create_by!(name: medal.name, parent_id: parent.id)
      medal.soldiers.find_each do |soldier|
        unless soldier.categories.exists?(id: cat.id)
          soldier.categories << cat
          puts "Linked #{soldier.id} -> #{cat.name}"
        end
      end
    end
    puts "Done."
  end
end
