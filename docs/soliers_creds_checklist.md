# Soldiers CRUD + Nested (Awards / Medals / Citations) — Quick Checklist

## 1) Routes
bin/rails routes -g "^soldiers#"
bin/rails routes -g "^involvements#"
bin/rails routes -g "^sources#autocomplete"
bin/rails routes -g regenerate_slug

## 2) Model wiring (recap)
- Soldier
  - has_many :awards, :soldier_medals
  - has_many :medals, through: :soldier_medals
  - has_many :citations, as: :citable
  - accepts_nested_attributes_for :awards, :soldier_medals, :citations
- Award belongs_to :soldier
- SoldierMedal belongs_to :soldier, :medal
- Medal has_many :soldier_medals; has_many :soldiers through :soldier_medals
- Citation belongs_to :source; belongs_to :citable (polymorphic)
  - accepts_nested_attributes_for :source

## 3) Strong params (SoldiersController)
Include:
- awards_attributes: [:id, :name, :country, :year, :note, :_destroy]
- soldier_medals_attributes: [:id, :medal_id, :year, :note, :_destroy]
- citations_attributes: [:id, :source_id, :_destroy, :page, :pages, :folio, :column, :line_number, :record_number, :locator, :image_url, :image_frame, :roll, :enumeration_district, :quote, :note, { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }]

## 4) Form smoke test
- New Soldier → add Award, Medal, Citation (with inline Source) → Create → Show
- Edit Soldier → add/remove child rows → Update

## 5) Console smoke test
s = Soldier.first || Soldier.create!(first_name: "Test", last_name: "User")
m = Medal.first  || Medal.create!(name: "Purple Heart", slug: "purple-heart")
s.awards.create!(name: "Community Service", country: "USA", year: 1950)
s.soldier_medals.create!(medal: m, year: 1945)
src = Source.first || Source.create!(title: "Boston Gazette", year: "1750")
s.citations.create!(source: src, pages: "12–13", note: "Snippet")
[s.reload.awards.size, s.soldier_medals.size, s.citations.size, s.sources.size]  # => [1,1,1,1]

## 6) JS sanity
- No 404s for Stimulus controllers
- `/sources/autocomplete?q=ha` returns JSON
