# Article + Source Verification Checklist
Generated: 2025-09-10

## Routes & pages
- [ ] `bin/rails routes | grep articles` shows `index/new/edit/show/destroy` and `regenerate_slug`
- [ ] `bin/rails routes | grep sources` shows `index/new/edit/show/destroy` and `regenerate_slug`
- [ ] Pages load: `/articles`, `/articles/new`, `/sources`, `/sources/new`

## Models
- **Article**
  - [ ] Includes `Sluggable`, `Citable`, `Categorizable`, `Relatable`
  - [ ] `has_many :citations, as: :citable`
  - [ ] `has_many :sources, through: :citations`
- **Source**
  - [ ] Includes `Sluggable`, `Categorizable`, `Relatable`
  - [ ] `has_many :citations`
  - [ ] `has_many :cited_articles, through: :citations, source: :citable, source_type: "Article"`
  - [ ] Accepts nested attributes for citations (if you allow creation inline)

## Forms
- **Article new/edit**
  - [ ] Title/body fields present
  - [ ] Categories multi-select (admin-only) appears
  - [ ] Citation fields render (via `_citations/fields`)
  - [ ] Inline Source creation fields include:
    - title, author, publisher, year, url
    - details, repository, link_url
  - [ ] Citation extras: pages, quote, note, remove checkbox
- **Source new/edit**
  - [ ] Title, author, publisher, year, url
  - [ ] Details, repository, link_url
  - [ ] Categories multi-select (admin-only)

## Show pages
- **Article show**
  - [ ] Title, body displayed
  - [ ] **Sources cited** section lists linked Sources
  - [ ] Each citation shows pages/quote/note
  - [ ] Admin-only **Regenerate slug** button present
- **Source show**
  - [ ] Title, metadata (author, publisher, year, url, details)
  - [ ] **Cited articles** section lists articles that used this source
  - [ ] Admin-only **Regenerate slug** button present

## Seeds/reset
- [ ] `bin/rails db:seed` creates at least one Source and one Article (if you seeded them)
- [ ] Reset (`db/seeds_reset.rb`) doesn’t wipe Sources/Citations unless told

## Console checks
```ruby
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
```
