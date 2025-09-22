# Relations Verification Checklist
Generated: 2025-09-10

This covers the generic polymorphic `Relation` model linking any two records.

## Schema sanity
- [ ] `relations` table has columns: from_type, from_id, to_type, to_id, relation_type, timestamps
- [ ] Unique index on `[from_type, from_id, to_type, to_id, relation_type]`
- [ ] Non-unique helper indexes on `from_type,from_id` and `to_type,to_id`

## Model
- [ ] `app/models/relation.rb`:
  ```ruby
  class Relation < ApplicationRecord
    belongs_to :from, polymorphic: true
    belongs_to :to,   polymorphic: true

    validates :relation_type, presence: true
    validates :from_type, uniqueness: { scope: [:from_id, :to_type, :to_id, :relation_type], message: "relationship already exists" }
  end
  ```

## Concern (Relatable)
- [ ] Included in models that should participate (e.g., Article, Source, Soldier)
- [ ] Provides helpers (example):
  ```ruby
  module Relatable
    extend ActiveSupport::Concern

    included do
      has_many :outgoing_relations, class_name: "Relation", as: :from, dependent: :destroy
      has_many :incoming_relations, class_name: "Relation", as: :to,   dependent: :destroy
    end

    def related_records
      (outgoing_relations.includes(:to).map(&:to) + incoming_relations.includes(:from).map(&:from)).uniq
    end

    def relate_to!(other, type: "related")
      Relation.create!(from: self, to: other, relation_type: type)
    end
  end
  ```

## Controller/UI
- [ ] (Optional) simple admin UI to add a relation from any show page
  - Hidden until `current_user&.admin?`
  - Uses a small form with:
    - `to_type` (string class name)
    - `to_id`
    - `relation_type` (default `"related"`)

## Show page
- [ ] Display **Related records** section:
  ```erb
  <% if @record.related_records.any? %>
    <h3>Related</h3>
    <ul>
      <% @record.related_records.each do |r| %>
        <li><%= link_to (r.try(:title) || r.try(:name) || r.to_s), r %> <small>(<%= r.class.name %>)</small></li>
      <% end %>
    </ul>
  <% end %>
  ```

## Console smoke tests
```ruby
a = Article.first || Article.create!(title: "Rel A", body: "Body")
s = Source.first  || Source.create!(title: "Rel S")
a.extend(Reloadable) rescue nil

# Create relation both ways
Relation.create!(from: a, to: s, relation_type: "cites")
Relation.create!(from: s, to: a, relation_type: "cited_by")

# Via helper (if Relatable mixed in)
a.relate_to!(s, type: "related")

# Check aggregation
a.related_records.map { |r| [r.class.name, r.try(:title) || r.try(:name)] }
```

## Gotchas
- Ensure both sides’ models are loaded (Zeitwerk naming must match file paths).
- Don’t allow duplicate rows: rely on the unique index + validation.
- Keep relation types short and normalized (e.g., `"related"`, `"cites"`, `"cited_by"`).
