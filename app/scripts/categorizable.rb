# lib/tasks/categorize.rake
require "csv"
require "set"

namespace :cat do
  ###########################################################################
  # IMPORTER (legacy join CSV)
  # Headers expected: id,article_id,category_id,created_at,updated_at
  #
  # ENV:
  #   CSV=tmp/article_categories_legacy.csv
  #   DRY_RUN=1                       # preview only
  #   STRICT=1                        # raise on missing Article/Category
  #   ARTICLE_ID_MAP=tmp/article_id_map.csv     # optional: old_id,new_id
  #   CATEGORY_ID_MAP=tmp/category_id_map.csv   # optional: old_id,new_id
  ###########################################################################
  desc "Import legacy Article↔Category links from CSV (headers: id,article_id,category_id,created_at,updated_at)"
  task import_articles_and_categories_from_csv: :environment do
    path   = ENV["CSV"] || "tmp/article_categories_legacy.csv"
    dry    = ENV["DRY_RUN"].to_s == "1"
    strict = ENV["STRICT"].to_s == "1"

    abort "CSV not found: #{path}" unless File.exist?(path)

    puts "== cat:import_articles_and_categories_from_csv"
    puts "CSV: #{path}"
    puts "DRY_RUN=#{dry} STRICT=#{strict}"

    # Optional ID maps if new app IDs differ from old app IDs
    load_id_map = ->(p) do
      map = {}
      if p && File.exist?(p)
        CSV.foreach(p, headers: true) do |r|
          old_id = (r["old_id"] || r["old"] || r[0]).to_i
          new_id = (r["new_id"] || r["new"] || r[1]).to_i
          map[old_id] = new_id if old_id.positive? && new_id.positive?
        end
        puts "Loaded ID map: #{p} (#{map.size} entries)"
      end
      map
    end
    article_map  = load_id_map.call(ENV["ARTICLE_ID_MAP"])
    category_map = load_id_map.call(ENV["CATEGORY_ID_MAP"])

    stat = {
      rows: 0, linked: 0, skipped_dup: 0,
      missing_article: 0, missing_category: 0, errors: 0
    }
    seen = Set.new

    CSV.foreach(path, headers: true) do |row|
      stat[:rows] += 1
      legacy_article_id  = row["article_id"].to_i
      legacy_category_id = row["category_id"].to_i
      next if legacy_article_id.zero? || legacy_category_id.zero?

      article_id  = article_map[legacy_article_id]  || legacy_article_id
      category_id = category_map[legacy_category_id] || legacy_category_id

      article  = Article.find_by(id: article_id)
      category = Category.find_by(id: category_id)

      if article.nil?
        stat[:missing_article] += 1
        msg = "Missing Article(#{article_id}) [legacy #{legacy_article_id}]"
        strict ? (raise msg) : (warn msg)
        next
      end
      if category.nil?
        stat[:missing_category] += 1
        msg = "Missing Category(#{category_id}) [legacy #{legacy_category_id}]"
        strict ? (raise msg) : (warn msg)
        next
      end

      pair = [article.id, category.id]
      if seen.include?(pair) || article.categories.exists?(category.id)
        stat[:skipped_dup] += 1
        next
      end

      if dry
        puts "DRY: link Article(#{article.id}) ⇢ Category(#{category.id})"
        stat[:linked] += 1
        seen << pair
      else
        begin
          article.categories << category
          stat[:linked] += 1
          seen << pair
        rescue => e
          stat[:errors] += 1
          warn "ERROR linking Article(#{article.id}) ⇢ Category(#{category.id}): #{e.class} #{e.message}"
        end
      end
    end

    puts "\n== Summary =="
    stat.each { |k, v| puts "%-18s %d" % ["#{k}:", v] }
    puts "Done."
  end

  ###########################################################################
  # REPORTS
  ###########################################################################

  # Compact, everything-you-need report for Articles + a few other models
  desc "Category status report (Articles + core models)"
  task report: :environment do
    puts "== Category Status Report =="

    # Articles
    total_articles = Article.count
    art_with_cat   = Article.joins(:categorizations).distinct.count
    puts "\n[Articles]"
    puts "  total:         #{total_articles}"
    puts "  with categories: #{art_with_cat}"
    puts "  without:       #{total_articles - art_with_cat}"

    top = Category.joins(:categorizations)
                  .where(categorizations: { categorizable_type: "Article" })
                  .group("categories.id", "categories.name", "categories.category_type")
                  .order(Arel.sql("COUNT(*) DESC"))
                  .limit(15)
                  .count
    if top.any?
      puts "  top categories (by Article usage):"
      top.each { |(id, name, type), cnt| puts "    • [#{id}] #{name} (#{type || 'n/a'}): #{cnt}" }
    else
      puts "  top categories: none"
    end

    missing = Article.left_joins(:categorizations)
                     .where(categorizations: { id: nil })
                     .order(created_at: :desc)
                     .limit(5)
                     .pluck(:id, :title)
    if missing.any?
      puts "  sample without categories:"
      missing.each { |id, title| puts "    • (#{id}) #{title}" }
    end

    # Other common models (only if they exist)
    %w[War Battle Soldier Source].each do |klass|
      model = klass.safe_constantize
      next unless model
      total = model.count
      withc = model.joins(:categorizations).distinct.count
      puts "\n[#{klass.pluralize}] total=#{total}, with_categories=#{withc}, without=#{total - withc}"
    end

    puts "\nDone."
  end

  # Deep dive: counts per category_type + totals
  desc "Breakdown of categories by type and usage"
  task breakdown: :environment do
    types = Category.group(:category_type).count
    puts "== Categories by type =="
    types.each { |t, c| puts "  #{t || 'n/a'}: #{c}" }

    puts "\n== Usage by type (Article links) =="
    usage = Category.joins(:categorizations)
                    .where(categorizations: { categorizable_type: "Article" })
                    .group("categories.category_type")
                    .count
    usage.each { |t, c| puts "  #{t || 'n/a'}: #{c}" }
  end

  # Orphans: categorizations pointing to missing records or categories
  desc "Find orphaned categorizations (missing record or category)"
  task orphans: :environment do
    puts "== Orphaned Categorizations =="
    orphans = Categorization.left_joins(:category)
                            .where(categories: { id: nil })
                            .or(
                              Categorization.where.not(categorizable_type: nil, categorizable_id: nil)
                                             .where.not(
                                               "EXISTS (SELECT 1 FROM #{ActiveRecord::Base.connection.quote_table_name('articles')} a WHERE categorizations.categorizable_type='Article' AND a.id=categorizations.categorizable_id)"
                                             )
                            )
    count = 0
    orphans.find_each do |c|
      puts "  id=#{c.id} category_id=#{c.category_id} on #{c.categorizable_type}(#{c.categorizable_id})"
      count += 1
      break if count >= 100
    end
    puts "Total (first 100 shown): #{[count, orphans.count].max}"
  end

  # Duplicates (defensive check if DB lacks a unique index)
  desc "Detect duplicate categorizations"
  task duplicates: :environment do
    puts "== Duplicate Categorizations =="
    dups = Categorization.group(:category_id, :categorizable_type, :categorizable_id)
                         .having("COUNT(*) > 1")
                         .count
    if dups.any?
      dups.each do |k, cnt|
        cat_id, type, rid = k
        puts "  #{type}(#{rid}) ⇢ Category(#{cat_id}): #{cnt}"
      end
    else
      puts "  None found."
    end
  end
end

# Convenience alias so `bin/rails categories:report` still works
namespace :categories do
  task report: "cat:report"
end
