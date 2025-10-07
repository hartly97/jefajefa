# Run this with: bin/rails runner scripts/import_soldiers_from_csv.rb
timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
dry_run_log_path = Rails.root.join("tmp/log", "dry_run_\#{timestamp}.log")

require 'csv'

SOLDIERS_CSV = Rails.root.join("db/data/soldiers.csv")

puts "📥 Importing soldiers..."
CSV.foreach(SOLDIERS_CSV, headers: true) do |row|
  soldier = File.open("/mnt/data/category_upgrade_bundle/tmp/log/dry_run.log", "a") { |f| f.puts("[DRY-RUN]" Would create Soldier: #{row["name"]}" if ENV["DRY_RUN"]) }}; next if ENV["DRY_RUN"]; Soldier.find_or_create_by!(id: row["id"]) do |s|
    s.name = row["name"]
    s.rank = row["rank"]
    s.notes = row["notes"]
  end

  # Optional: Tag assignment via categories
  tags = row["tags"].to_s.split(",").map(&:strip)
  tags.each do |tag|
    next if tag.blank?
    category = File.open("/mnt/data/category_upgrade_bundle/tmp/log/dry_run.log", "a") { |f| f.puts("[DRY-RUN]" Would create Category: #{tag}" if ENV["DRY_RUN"]) }}; next if ENV["DRY_RUN"]; Category.find_or_create_by!(name: tag, category_type: "topic")
    File.open("/mnt/data/category_upgrade_bundle/tmp/log/dry_run.log", "a") { |f| f.puts("[DRY-RUN]" Would tag Soldier #{soldier.id} with Category #{category.name}" if ENV["DRY_RUN"]) }}; next if ENV["DRY_RUN"]; Categorization.find_or_create_by!(category: category, categorizable: soldier)
  end
end

puts "✅ Soldier import complete."