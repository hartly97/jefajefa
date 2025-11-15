namespace :sources do
  desc "Mark top N sources by citation count as common (default N=20, min_cites=3)"
  task :mark_common, [:top, :min_cites] => :environment do |_, args|
    top       = (args[:top] || 20).to_i
    min_cites = (args[:min_cites] || 3).to_i

    counts = Citation.group(:source_id).count
    ranked = counts.select { |_, c| c >= min_cites }
                   .sort_by { |_, c| -c }
                   .first(top)

    ids = ranked.map(&:first)
    updated = Source.where(id: ids).update_all(common: true)
    puts "[sources] Marked #{updated} sources as common (top=#{top}, min_cites=#{min_cites})."
  end
end

namespace :sources do
  desc "Mark top N sources by citation count as common (TOP, MIN_CITES envs supported). DRY=1 to preview."
  task :mark_common, [:top, :min_cites] => :environment do |_, args|
    top       = (args[:top] || ENV["TOP"] || 20).to_i
    min_cites = (args[:min_cites] || ENV["MIN_CITES"] || 3).to_i
    dry       = ENV["DRY"] == "1"

    counts = Citation.group(:source_id).count  # { source_id => count }
    ranked = counts.select { |_, c| c >= min_cites }
                   .sort_by { |_, c| -c }
                   .first(top)

    ids = ranked.map(&:first)
    puts "[sources] candidates=#{ids.size} (top=#{top}, min_cites=#{min_cites})"
    ranked.each { |id, c| puts "  - #{id}: #{c} cites  #{Source.find_by(id: id)&.title}" }

    if dry
      puts "[sources] DRY=1  not updating."
    else
      updated = Source.where(id: ids).update_all(common: true, updated_at: Time.current)
      puts "[sources] Marked #{updated} sources as common."
    end
  end

  desc "Unmark sources with < MIN_CITES citations (MIN_CITES env supported). DRY=1 to preview."
  task :unmark_rare, [:min_cites] => :environment do |_, args|
    min_cites = (args[:min_cites] || ENV["MIN_CITES"] || 1).to_i
    dry       = ENV["DRY"] == "1"

    counts = Citation.group(:source_id).count
    demote_ids = Source.where(common: true).pluck(:id).select { |id| (counts[id] || 0) < min_cites }

    puts "[sources] will unmark #{demote_ids.size} sources (min_cites=#{min_cites})"
    demote_ids.each { |id| puts "  - #{id}: #{counts[id].to_i} cites  #{Source.find_by(id: id)&.title}" }

    if dry
      puts "[sources] DRY=1  not updating."
    else
      updated = Source.where(id: demote_ids).update_all(common: false, updated_at: Time.current)
      puts "[sources] Unmarked #{updated} sources."
    end
  end

  desc "Manually mark given titles as common. TITLES='Title A;;Title B' (use double semicolons as separator). DRY=1 to preview."
  task :promote_titles => :environment do
    raw = ENV["TITLES"].to_s
    titles = raw.split(";;").map(&:strip).reject(&:blank?)
    abort "Provide TITLES='Title A;;Title B'" if titles.empty?

    scope = Source.where("LOWER(title) IN (?)", titles.map(&:downcase))
    puts "[sources] found #{scope.count}/#{titles.size}"
    scope.each { |s| puts "  - #{s.id}  #{s.title}" }

    if ENV["DRY"] == "1"
      puts "[sources] DRY=1  not updating."
    else
      updated = scope.update_all(common: true, updated_at: Time.current)
      puts "[sources] Marked #{updated} as common."
    end
  end
end
