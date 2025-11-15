# lib/tasks/slugs.rake
namespace :slugs do
  desc "Backfill missing slugs across models"
  task backfill: :environment do
    models = %w[
      Soldier Award Medal War Battle Cemetery Source Category Article Census CensusEntry
    ].map { |n| n.safe_constantize }.compact

    models.each do |k|
      next unless k.column_names.include?("slug")
      puts "Backfilling #{k.name}"
      k.where(slug: [nil, ""]).find_each do |r|
        begin
          r.regenerate_slug!
        rescue => e
          warn "   #{k.name}##{r.id}: #{e.message}"
        end
      end
    end
    puts "Done."
  end
end
