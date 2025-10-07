# Endicott App – Commands & Call Patterns (Cheat Sheet)

Everyday commands, routes, helpers, and console snippets you’ll use across the app.

---

## 0) Quick maintenance commands

```bash
bin/rails s
bin/rails c
bin/rails db:migrate
bin/rails db:seed
bin/rails routes -g article
bin/spring stop

# Stimulus (importmap)
bin/rails stimulus:manifest:update
```
---

## 1) Routes/helpers: not nested

### Articles
```ruby
# routes.rb
resources :articles do
  patch :regenerate_slug, on: :member
end

# helpers
articles_path
new_article_path
article_path(@article)
edit_article_path(@article)
regenerate_slug_article_path(@article)   # PATCH
```

### Censuses
```ruby
resources :censuses
censuses_path; new_census_path; census_path(@census); edit_census_path(@census)
```

### Sources (with autocomplete)
```ruby
resources :sources do
  collection { get :autocomplete }
end
sources_path; new_source_path; autocomplete_sources_path(q: "har")
```

### Soldiers / Cemeteries
```ruby
resources :soldiers
resources :cemeteries
```

---

## 2) Slugs (Sluggable)

```rb
# console one-liners
Article.find_each { |a| a.regenerate_slug! if a.slug.blank? }
Census.find_each  { |c| c.regenerate_slug! if c.slug.blank() }
```
Use `/articles/some-slug` or `/censuses/uk-1851-...`

---

## 3) Citations (polymorphic)

Any model that `include Citable` gets:
```rb
has_many :citations, as: :citable, dependent: :destroy
has_many :sources,   through: :citations
accepts_nested_attributes_for :citations, allow_destroy: true
```

**Nested form block**
```erb
<%= form_with model: @article do |f| %>
  <%= render "citations/sections", f: f, sources: @sources %>
  <%= f.submit %>
<% end %>
```

**Stimulus wiring (sections partial)**
```erb
<div data-controller="citations" data-citations-index-value="<%= f.object.citations.size %>">
  <div data-citations-target="list">
    <%= f.fields_for :citations do |cf| %>
      <%= render "citations/fields", cf: cf, sources: (@sources || Source.order(:title)) %>
    <% end %>
  </div>

  <template data-citations-target="template">
    <%= f.fields_for :citations, Citation.new, child_index: "NEW_RECORD" do |cf| %>
      <%= render "citations/fields", cf: cf, sources: (@sources || Source.order(:title)) %>
    <% end %>
  </template>

  <button type="button" class="btn btn-outline-primary mt-2" data-action="click->citations#add">
    + Add another citation
  </button>
</div>
```

**Fields partial top**
```erb
<div class="border p-3 mb-3 rounded citation-fields" data-citations-wrapper>
  <div class="d-flex justify-content-between align-items-center mb-2">
    <strong>Citation</strong>
    <button type="button" class="btn btn-sm btn-outline-danger" data-action="click->citations#remove">Remove</button>
  </div>
  <%= cf.check_box :_destroy, class: "d-none" %>
</div>
```

**Strong params reminder**
```rb
citations_attributes: [
  :id, :source_id, :pages, :quote, :note, :volume, :issue, :folio, :page, :column,
  :line_number, :record_number, :image_url, :image_frame, :roll, :enumeration_district,
  :locator, :_destroy,
  { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }
]
```

---

## 4) Categories (Categorizable)

```rb
# add/remove
a = Article.first
cat = Category.find_or_create_by!(name: "Genealogy")
a.categories << cat unless a.categories.exists?(cat.id)
a.categories.destroy(cat)

# list items
cat.articles.pluck(:id, :title)
```

---

## 5) Involvements (Soldier ↔ War/Battle/Cemetery)

> Articles are NOT involvable by design.

```rb
# soldiers in a war / battle
War.first.soldiers.limit(5).pluck(:last_name)
Battle.first.soldiers.limit(5).pluck(:last_name, :first_name)

# link a soldier to a battle
s = Soldier.first; b = Battle.first
Involvement.create!(participant: s, involvable: b)
```

---

## 6) Pagination (will_paginate)

**Initializer**
```rb
# config/initializers/will_paginate.rb
require "will_paginate"
require "will_paginate/active_record"
require "will_paginate/view_helpers/action_view"
```

**Helper wrapper**
```rb
# app/helpers/pagination_helper.rb
def paginate(collection, **opts)
  return unless collection.respond_to?(:total_pages) && collection.total_pages.to_i > 1
  will_paginate(collection, { renderer: PaginationHelper::BootstrapLinkRenderer }.merge(opts))
end
```

**Controller**
```rb
@articles = Article.order(created_at: :desc).paginate(page: params[:page], per_page: 20)
```

**View**
```erb
<%= paginate @articles %>
```

---

## 7) External images (SmugMug)

**Model method**
```rb
def display_image_url(view_context = nil)
  return external_image_url if external_image_url.present?
  return view_context.url_for(image) if respond_to?(:image) && image.respond_to?(:attached?) && image.attached? && view_context
  nil
end
```

**Form fields:** `external_image_url`, `external_image_caption`, `external_image_credit`

---

## 8) Console snippets

```rb
# Sources used by an Article
a = Article.first
a.sources.pluck(:title)

# Sources that cite any Soldier
Source.joins(:citations).where(citations: { citable_type: "Soldier" }).distinct.pluck(:title)

# Census entries for a census
c = Census.first
CensusEntry.where(census_id: c.id).order(:linenumber).pluck(:householdid, :linenumber, :firstname, :lastname)
```
# Sources used by an Article
a = Article.first
a.sources.pluck(:title)

# Sources that cite any Soldier
Source.joins(:citations).where(citations: { citable_type: "Soldier" }).distinct.pluck(:title)

# Census entries for a census
c = Census.first
CensusEntry.where(census_id: c.id).order(:linenumber).pluck(:householdid, :linenumber, :firstname, :lastname)
