# Console & Grep Tricks Cheat-Sheet
Generated: 2025-09-10

## Rails Console (`bin/rails console`)

### Verify modules included
```ruby
defined?(Sluggable)               # => "constant"
Source.included_modules.include?(Sluggable)  # => true/false
```

### Quick create with nested citations
```ruby
s = Source.create!(title: "Test Source")
a = Article.create!(
  title: "Has Citation",
  body: "Body here",
  citations_attributes: [
    { source_id: s.id, pages: "1-2" }
  ]
)
a.citations.first.source == s   # => true
```

### Add multiple citations to same source
```ruby
a.update!(citations_attributes: [
  { source_id: s.id, pages: "1-2" },
  { source_id: s.id, pages: "40-41" }
])
a.citations.pluck(:pages)  # => ["1-2", "40-41"]
```

### Check associations
```ruby
s = Source.last
s.citations.count
s.cited_articles.pluck(:title)
```

### Regenerate slug manually
```ruby
a = Article.last
a.regenerate_slug!
```

---

## Grep commands (run in project root)

### Find concern definitions
```bash
grep -R "module Categorizable" -n app
grep -R "module Citable" -n app
```

### Find models using author/publisher/year/url
```bash
grep -R "author" -n app db
grep -R "publisher" -n app db
grep -R "year" -n app db
grep -R "url\b" -n app db | grep -v link_url
```

### Find render form usage
```bash
grep -nR 'render "form"' app/views/articles
grep -nR '<form' app/views/articles
```

### Check migrations for soldier
```bash
grep -R "class CreateSoldiers" db/migrate -n
ls -1 db/migrate | grep -i soldier
```

---

## DB Console (SQLite/Postgres)

List indexes:
```ruby
ActiveRecord::Base.connection.indexes(:citations).map { |i| [i.name, i.unique, i.columns] }
```

Check schema version:
```bash
bin/rails db:version
```

---
Keep this file (`CONSOLE_TRICKS.md`) around as your quick reference!

# show line numbers and reveal non-printables (^ and M- escapes)
cat -n -v config/routes.rb

# also show all non-ASCII bytes in hex
xxd -g 1 -c 256 config/routes.rb

Step 4 — Confirm only one declaration per resource

Double-check no duplicates elsewhere (sometimes a merge leaves a second block below):

grep -nE 'resources :articles|resources :soldiers|resources :sources' config/routes.rb

Soldier.count; Source.count; Category.count

nl -ba config/routes.rb | grep -A2 soldiers


# Article with citation
s = Source.first || Source.create!(title: "Parish Register")
a = Article.create!(title: "Parish Births", body: "Notes", citations_attributes: [{ source_id: s.id, pages: "22" }])
a.sources.first == s  # => true

# Multiple citations
a.update!(citations_attributes: [
  { source_id: s.id, pages: "22" },
  { source_id: s.id, pages: "45" }
])
a.citations.count   # => 2

# Source sees its articles
s.cited_articles.pluck(:title)

# Slug regen
a.regenerate_slug!
s.regenerate_slug!


# Slug generated?
s = Soldier.create!(first_name: "Check", last_name: "Slug"); s.slug.present?

# Source + citation
src = Source.first || Source.create!(title: "Belstone Parish Records")
s.update!(citations_attributes: [{ source_id: src.id, pages: "12" }])
s.sources.pluck(:title)

# Multiple citations to same source
s.update!(citations_attributes: [{ source_id: src.id, pages: "12" }, { source_id: src.id, pages: "13" }])
s.citations.where(source: src).count  # expect >= 2

# Award + involvement
m = Medal.first || Medal.create!(name: "Bronze Star")
s.awards.create!(medal: m, year: 1944)
w = War.first || War.create!(name: "World War II")
s.involvements.create!(involvable: w, role: "Infantry", year: 1944)

# Should each print one exact match:
grep -n "^class Article <" app/models/article.rb
grep -n "^class Source <"  app/models/source.rb
grep -n "^class Citation <" app/models/citation.rb
grep -n "^class Categorization <" app/models/categorization.rb
grep -n "^module Citable" app/models/concerns/citable.rb
grep -n "^module Categorizable" app/models/concerns/categorizable.rb
grep -n "^module Sluggable" app/models/concerns/sluggable.rb

# proves whether the app can boot at all
bin/rails runner 'puts "BOOT OK"'

# see what Zeitwerk thinks (autoload issues)
bin/rails zeitwerk:check

# proves whether the app can boot at all
bin/rails runner 'puts "BOOT OK"'

# see what Zeitwerk thinks (autoload issues)
bin/rails zeitwerk:check

tail -n 200 log/development.log
See what’s poking your port:
lsof -i :3000


Console Sanity Checks
Citations
Always show details
s = Source.create!(title: "Parish Register")
a = Article.create!(title: "Belstone Births", body: "…",
  citations_attributes: [{ source_id: s.id, pages: "10-12" }]
)
a.sources.pluck(:title)        # => ["Parish Register"]
s.cited_articles.pluck(:title) # => ["Belstone Births"]

Categories
Always show details
topic = Category.create!(name: "Parish", category_type: "topic", slug: "parish")
a.update!(category_ids: [topic.id])
a.categories.pluck(:name)      # => ["Parish"]

Relations
Always show details
a = Article.first
b = Article.last
Relation.create!(from: a, to: b, relation_type: "related")

a.related                      # => [b]
b.related                      # => [a]

ruby -c app/controllers/articles_controller.rb
ruby -c app/controllers/categories_controller.rb
ruby -c app/controllers/categorizations_controller.rb

bin/rails routes | grep regenerate_slug


ruby -c app/controllers/soldiers_controller.rb
bin/rails routes | grep regenerate_slug
grep -R "Regenerate slug" -n app/views/soldiers

ruby -c app/controllers/wars_controller.rb
bin/rails routes | grep wars
bin/rails routes | grep regenerate_slug

# Console & Grep Tricks Cheat-Sheet
Generated: 2025-09-10

## Rails Console (`bin/rails console`)

### Verify modules included
```ruby
defined?(Sluggable)               # => "constant"
Source.included_modules.include?(Sluggable)  # => true/false
```

### Quick create with nested citations
```ruby
s = Source.create!(title: "Test Source")
a = Article.create!(
  title: "Has Citation",
  body: "Body here",
  citations_attributes: [
    { source_id: s.id, pages: "1-2" }
  ]
)
a.citations.first.source == s   # => true
```

### Add multiple citations to same source
```ruby
a.update!(citations_attributes: [
  { source_id: s.id, pages: "1-2" },
  { source_id: s.id, pages: "40-41" }
])
a.citations.pluck(:pages)  # => ["1-2", "40-41"]
```

### Check associations
```ruby
s = Source.last
s.citations.count
s.cited_articles.pluck(:title)
```

### Regenerate slug manually
```ruby
a = Article.last
a.regenerate_slug!
```

---

## Grep commands (run in project root)

### Find concern definitions
```bash
grep -R "module Categorizable" -n app
grep -R "module Citable" -n app
```

### Find models using author/publisher/year/url
```bash
grep -R "author" -n app db
grep -R "publisher" -n app db
grep -R "year" -n app db
grep -R "url\b" -n app db | grep -v link_url
```

### Find render form usage
```bash
grep -nR 'render "form"' app/views/articles
grep -nR '<form' app/views/articles
```

### Check migrations for soldier
```bash
grep -R "class CreateSoldiers" db/migrate -n
ls -1 db/migrate | grep -i soldier
```

---

## DB Console (SQLite/Postgres)

List indexes:
```ruby
ActiveRecord::Base.connection.indexes(:citations).map { |i| [i.name, i.unique, i.columns] }
```

Check schema version:
```bash
bin/rails db:version
```

---
Keep this file (`CONSOLE_TRICKS.md`) around as your quick reference!
