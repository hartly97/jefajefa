# 📖 Polymorphic Associations Cheat Sheet

## 🔗 Citable Concern (citations + sources)
```ruby
# app/models/concerns/citable.rb
module Citable
  extend ActiveSupport::Concern

  included do
    has_many :citations, as: :citable, dependent: :destroy, inverse_of: :citable
    has_many :sources, through: :citations
  end
end
```

```ruby
# app/models/citation.rb
class Citation < ApplicationRecord
  belongs_to :citable, polymorphic: true, inverse_of: :citations
  belongs_to :source,  inverse_of: :citations

  accepts_nested_attributes_for :source,
    reject_if: ->(attrs) { attrs['title'].blank? }
end
```

---

## 🏷️ Categorizable Concern (categorizations + categories)
```ruby
# app/models/concerns/categorizable.rb
module Categorizable
  extend ActiveSupport::Concern

  included do
    has_many :categorizations, as: :categorizable,
                               dependent: :destroy,
                               inverse_of: :categorizable
    has_many :categories, through: :categorizations
  end
end
```

```ruby
# app/models/categorization.rb
class Categorization < ApplicationRecord
  belongs_to :category
  belongs_to :categorizable, polymorphic: true, inverse_of: :categorizations
end
```

---

## 🔀 Relatable Concern (general-purpose relations)
```ruby
# app/models/relation.rb
class Relation < ApplicationRecord
  belongs_to :from, polymorphic: true
  belongs_to :to,   polymorphic: true

  validates :relation_type, presence: true
  validates :from_type, uniqueness: { scope: [:from_id, :to_type, :to_id, :relation_type] }
  validate  :prevent_self_relation

  private
  def prevent_self_relation
    if from_type == to_type && from_id == to_id
      errors.add(:base, "Cannot relate a record to itself.")
    end
  end
end
```

```ruby
# app/models/concerns/relatable.rb
module Relatable
  extend ActiveSupport::Concern

  included do
    has_many :outgoing_relations, class_name: "Relation", as: :from, dependent: :destroy
    has_many :incoming_relations, class_name: "Relation", as: :to,   dependent: :destroy
  end

  def related(relation_type: nil)
    outs = relation_type ? outgoing_relations.where(relation_type:) : outgoing_relations
    ins  = relation_type ? incoming_relations.where(relation_type:) : incoming_relations
    outs.map(&:to) + ins.map(&:from)
  end
end
```

---

## 📦 Example Models

### Article
```ruby
class Article < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable
  include Relatable   # optional, if you want free-form relations

  validates :title, presence: true
  def slug_source = title
end
```

### Source
```ruby
class Source < ApplicationRecord
  include Sluggable
  include Categorizable

  has_many :citations, dependent: :restrict_with_error, inverse_of: :source

  # Which Articles cite this Source?
  has_many :cited_articles,
           through: :citations,
           source: :citable,
           source_type: "Article"

  validates :title, presence: true
  def slug_source = title
end
```

### Soldier
```ruby
class Soldier < ApplicationRecord
  include Sluggable
  include Citable
  include Categorizable
  include Relatable

  def slug_source = "#{last_name}-#{first_name}"
end
```

---

## 🛠️ Console Sanity Checks

### Citations
```ruby
s = Source.create!(title: "Parish Register")
a = Article.create!(title: "Belstone Births", body: "…",
  citations_attributes: [{ source_id: s.id, pages: "10-12" }]
)
a.sources.pluck(:title)        # => ["Parish Register"]
s.cited_articles.pluck(:title) # => ["Belstone Births"]
```

### Categories
```ruby
topic = Category.create!(name: "Parish", category_type: "topic", slug: "parish")
a.update!(category_ids: [topic.id])
a.categories.pluck(:name)      # => ["Parish"]
```

### Relations
```ruby
a = Article.first
b = Article.last
Relation.create!(from: a, to: b, relation_type: "related")

a.related                      # => [b]
b.related                      # => [a]
```
