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
