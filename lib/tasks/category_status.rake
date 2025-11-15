# lib/tasks/category_status.rake
namespace :categories do
  desc "Report category stats for Articles (and optionally other models)"
  task report: :environment do
    puts "== Category Status Report =="

    # --- Articles ---
    total_articles = Article.count
    art_with_cat = Article.joins(:categorizations).distinct.count
    art_without_cat = total_articles - art_with_cat

    puts "\n[Articles]"
    puts "  total:         #{total_articles}"
    puts "  with categories: #{art_with_cat}"
    puts "  without:       #{art_without_cat}"

    # Top categories used by Articles
    top = Category.joins(:categorizations)
                  .where(categorizations: { categorizable_type: "Article" })
                  .group("categories.id", "categories.name", "categories.category_type")
                  .order(Arel.sql("COUNT(*) DESC"))
                  .limit(15)
                  .count
    if top.any?
      puts "  top categories (by Article usage):"
      top.each do |(cat_id, name, cat_type), cnt|
        puts "     [#{cat_id}] #{name} (#{cat_type || 'n/a'}): #{cnt}"
      end
    else
      puts "  top categories: none"
    end

    # Sanity check: list a few Articles missing categories
    missing = Article.left_joins(:categorizations)
                     .where(categorizations: { id: nil })
                     .order(created_at: :desc)
                     .limit(5)
                     .pluck(:id, :title)
    if missing.any?
      puts "  sample without categories:"
      missing.each { |id, title| puts "     (#{id}) #{title}" }
    end

    # --- Optional: other categorizables (uncomment as needed) ---
     %w[War Battle Soldier Source].each do |klass|
       model = klass.constantize
       total = model.count
       with_cat = model.joins(:categorizations).distinct.count
       puts "\n[#{klass.pluralize}] total=#{total}, with_categories=#{with_cat}, without=#{total - with_cat}"
     end

    puts "\nDone."
  end
end
