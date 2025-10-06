# lib/tasks/import_articles_and_categories_from_csv.rake
require "csv"
require "set"

namespace :cat do
  desc "Import legacy Article↔Category links from CSV with headers: id,article_id,category_id,created_at,updated_at
ENV:
  CSV=tmp/article_categories_legacy.csv
  DRY_RUN=1                  # preview only
  STRICT=1                   # raise on missing Article/Category
  ARTICLE_ID_MAP=tmp/article_id_map.csv     # optional: CSV old_id,new_id
  CATEGORY_ID_MAP=tmp/category_id_map.csv   # optional: CSV old_id,new_id"
  task import_articles_and_categories_from_csv: :environment do
    path   = ENV["CSV"] || "tmp/article_categories_legacy.csv"
    dry    = ENV["DRY_RUN"].to_s == "1"
    strict = ENV["STRICT"].to_s == "1"

    abort "CSV not found: #{path}" unless File.exist?(path)

    puts "== cat:import_articles_and_categories_from_csv"
    puts "CSV: #{path}"
    puts "DRY_RUN=#{dry} STRICT=#{strict}"

    # Optional ID maps if your new app has different IDs than the old one
    load_id_map = ->(p) do
      m = {}
      if p && File.exist?(p)
        CSV.foreach(p, headers: true) do |r|
          old_id = r["old_id"] || r["old"] || r[0]
          new_id = r["new_id"] || r["new"] || r[1]
          next unless old_id && new_id
          m[old_id.to_i] = new_id.to_i
        end
        puts "Loaded ID map: #{p} (#{m.size} entries)"
      end
      m
    end

    article_map  = load_id_map.call(ENV["ARTICLE_ID_MAP"])
    category_map = load_id_map.call(ENV["CATEGORY_ID_MAP"])

    # Uniqueness guard within this run
    seen = Set.new

    stat = {
      rows: 0, linked: 0, skipped_dup: 0,
      missing_article: 0, missing_category: 0, errors: 0
    }

    # Preload a minimal set for faster existence checks
    # (If your tables are small, this is fine; otherwise we’ll still hit the DB.)
    cat_scope = Category.all
    art_scope = Article.all

    CSV.foreach(path, headers: true) do |row|
      stat[:rows] += 1
      legacy_article_id = row["article_id"].to_i
      legacy_category_id = row["category_id"].to_i
      next if legacy_article_id.zero? || legacy_category_id.zero?

      article_id = article_map[legacy_article_id] || legacy_article_id
      category_id = category_map[legacy_category_id] || legacy_category_id

      article = art_scope.find_by(id: article_id)
      unless article
        stat[:missing_article] += 1
        msg = "Missing Article(#{article_id}) [legacy #{legacy_article_id}]"
        strict ? (raise msg) : (warn msg)
        next
      end

      category = cat_scope.find_by(id: category_id)
      unless category
        stat[:missing_category] += 1
        msg = "Missing Category(#{category_id}) [legacy #{legacy_category_id}]"
        strict ? (raise msg) : (warn msg)
        next
      end

      key = [article.id, category.id]
      # Skip if we’ve already linked in this run, or the DB already has it
      if seen.include?(key) || article.categories.exists?(category.id)
        stat[:skipped_dup] += 1
        next
      end

      if dry
        puts "DRY: link Article(#{article.id}) ⇢ Category(#{category.id})"
        stat[:linked] += 1
        seen << key
      else
        begin
          article.categories << category
          stat[:linked] += 1
          seen << key
        rescue => e
          stat[:errors] += 1
          warn "ERROR linking Article(#{article.id}) ⇢ Category(#{category.id}): #{e.class} #{e.message}"
          next
        end
      end
    end

    puts "\n== Summary =="
    stat.each { |k, v| puts "%-18s %d" % ["#{k}:", v] }
    puts "Done."
  end
end
