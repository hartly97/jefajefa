Here’s a quick console test to sanity-check your Relations setup 🚀

# Make a sample Article and Soldier
a = Article.create!(title: "Relation Test Article", body: "Body text")
s = Soldier.create!(first_name: "John", last_name: "Doe")

# Create a relation (article -> soldier)
rel = Relation.create!(from: a, to: s, relation_type: "mentions")

# Check it worked
[
  rel.relation_type,          # => "mentions"
  rel.from_type, rel.from_id, # => "Article", <id>
  rel.to_type, rel.to_id,     # => "Soldier", <id>
  a.related_records.map(&:class).map(&:name),  # => ["Soldier"]
  s.related_records.map(&:class).map(&:name)   # => ["Article"]

  Soldier.create!(
  first_name: "Test",
  last_name: "Person",
  citations_attributes: [
    { pages: "55", source_attributes: { title: "Devon Muster Roll", author: "Jane Doe", year: "1625" } }
  ]
).citations.first.source.attributes.slice("title","author","year")

{"title"=>"Devon Muster Roll", "author"=>"Jane Doe", "year"=>"1625"}

Article.create!(
  title: "Nested Test",
  body: "Checking nested attributes",
  citations_attributes: [
    { pages: "10-11", source_attributes: { title: "Belstone Parish Records", author: "John Smith", year: "1750" } }
  ]
).citations.first.source.attributes.slice("title","author","year")

