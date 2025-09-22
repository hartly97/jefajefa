Nested Soldier/Source Test
Always show details
Soldier.create!(first_name: "Test", last_name: "Person",
  citations_attributes: [{{ pages: "55", source_attributes: {{ title: "Devon Muster Roll", author: "Jane", year: "1625" }} }}]
).citations.first.source.attributes.slice("title","author","year")

Relations Quick Test
Always show details
a = Article.create!(title: "Relation Test", body: "Body")
s = Soldier.create!(first_name: "John", last_name: "Doe")
rel = Relation.create!(from: a, to: s, relation_type: "mentions")
[a.related_records.map(&:class).map(&:name), s.related_records.map(