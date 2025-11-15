Article.find_each { |a| a.regenerate_slug! if a.slug.blank? }
Census.find_each  { |c| c.regenerate_slug! if c.slug.blank() }
# add/remove
a = Article.first
cat = Category.find_or_create_by!(name: "Genealogy")
a.categories << cat unless a.categories.exists?(cat.id)
a.categories.destroy(cat)

# list items
cat.articles.pluck(:id, :title)

nvolvements (Soldier ↔ War/Battle/Cemetery)

Articles are NOT involvable by design.

# Sources used by an Article
a = Article.first
a.sources.pluck(:title)

# Sources that cite any Soldier
Source.joins(:citations).where(citations: { citable_type: "Soldier" }).distinct.pluck(:title)

# Census entries for a census
c = Census.first
CensusEntry.where(census_id: c.id).order(:linenumber).pluck(:householdid, :linenumber, :firstname, :lastname)