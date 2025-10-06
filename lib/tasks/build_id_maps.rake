# lib/tasks/build_id_maps.rake
require "csv"

namespace :cat do
  # Build Article ID map via title (old -> new)
  # ENV: OLD=tmp/old_articles.csv OUT=tmp/article_id_map.csv
  # old CSV needs headers: id,title
  desc "Build Article ID map (old->new) by matching title"
  task build_article_id_map: :environment do
    old = ENV["OLD"] || "tmp/old_articles.csv"
    out = ENV["OUT"] || "tmp/article_id_map.csv"
    abort "Missing #{old}" unless File.exist?(old)

    norm = ->(s) { s.to_s.strip.gsub(/\s+/, " ") }
    nidx = {}
    Article.find_each { |a| nidx[norm.call(a.title).downcase] = a.id }

    rows = []
    CSV.foreach(old, headers: true) do |r|
      old_id = r["id"].to_i
      title  = norm.call(r["title"])
      next if old_id.zero? || title.blank?
      new_id = nidx[title.downcase]
      rows << [old_id, new_id, title]
    end

    CSV.open(out, "w") do |csv|
      csv << %w[old_id new_id title]
      rows.each { |row| csv << row }
    end

    puts "Wrote #{out} (#{rows.size} rows)"
    misses = rows.count { |_, nid, _| nid.nil? }
    puts "Unmatched titles: #{misses}" if misses.positive?
  end

  # Build Category ID map via (name, type)
  # ENV: OLD=tmp/old_categories.csv OUT=tmp/category_id_map.csv
  # old CSV needs headers: id,name,category_type
  desc "Build Category ID map (old->new) by matching name & type"
  task build_category_id_map: :environment do
    old = ENV["OLD"] || "tmp/old_categories.csv"
    out = ENV["OUT"] || "tmp/category_id_map.csv"
    abort "Missing #{old}" unless File.exist?(old)

    norm = ->(s) { s.to_s.strip.gsub(/\s+/, " ") }
    nidx = Hash.new { |h,k| h[k] = {} }
    Category.find_each { |c| nidx[norm.call(c.name).downcase][c.category_type.to_s] = c.id }

    rows = []
    CSV.foreach(old, headers: true) do |r|
      old_id = r["id"].to_i
      name   = norm.call(r["name"])
      ctype  = norm.call(r["category_type"])
      next if old_id.zero? || name.blank?
      new_id = nidx[name.downcase][ctype.to_s]
      rows << [old_id, new_id, name, ctype]
    end

    CSV.open(out, "w") do |csv|
      csv << %w[old_id new_id name category_type]
      rows.each { |row| csv << row }
    end

    puts "Wrote #{out} (#{rows.size} rows)"
    misses = rows.count { |_, nid, _| nid.nil? }
    puts "Unmatched categories: #{misses}" if misses.positive?
  end
end
