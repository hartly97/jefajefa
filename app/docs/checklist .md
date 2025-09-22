Console & Grep Tricks
Generated: {today}

Rails console
Always show details
defined?(Sluggable)
Source.included_modules.include?(Sluggable)

s = Source.first || Source.create!(title: "Test Source")
a = Article.create!(title: "Has Citation", body: "Body",
  citations_attributes: [{{ source_id: s.id, pages: "1-2" }}])
a.sources.first == s

a.update!(citations_attributes: [
  {{ source_id: s.id, pages: "1-2" }},
  {{ source_id: s.id, pages: "40-41" }}
])
a.citations.count

Grep
Always show details
grep -R "module Categorizable" -n app
grep -R "module Citable" -n app
grep -R "author" -n app db
grep -R "publisher" -n app db
grep -R "year" -n app db
grep -R "url\\b" -n app db | grep -v link_url


""",
"docs/ARTICLE_SOURCE_CHECKLIST.md": f"""# Article + Source Verification
Generated: {today}

Routes present for articles/sources (and regenerate_slug)

Article form shows citations + inline source fields (title/author/publisher/year/url/etc.)

Article show lists Sources cited

Source show lists Cited articles

Console:

Always show details
s = Source.first || Source.create!(title: "Parish Register")
a = Article.create!(title: "Parish Births", body: "Notes",
  citations_attributes: [{{ source_id: s.id, pages: "22" }}])
a.sources.first == s
s.cited_articles.pluck(:title)


""",
"docs/SOLDIER_CHECKLIST.md": f"""# Soldier Verification
Generated: {today}

Routes present for soldiers (and regenerate_slug)

Form has name/birth/death/cemetery + citations

Show lists Sources cited; admin slug button visible if admin

Console:

Always show details
src = Source.first || Source.create!(title: "Belstone Parish Records")
so = Soldier.create!(first_name: "Test", last_name: "Person")
so.update!(citations_attributes: [{{ source_id: src.id, pages: "12" }}])
so.sources.pluck(:title)


""",
"docs/RELATIONS_CHECKLIST.md": f"""# Relations Verification
Generated: {today}

relations table has from_type/from_id/to_type/to_id/relation_type (+ unique index)

Model validates uniqueness of relation triple + type

Relatable concern aggregates related records

Console:

Always show details
a = Article.first || Article.create!(title: "Rel A", body: "Body")
s = Source.first  || Source.create!(title: "Rel S")
Relation.create!(from: a, to: s, relation_type: "cites")


""",
"BUNDLE_CONTENTS.md": f"""# Bundle Contents
Generated: {today}

Core app code (models/controllers/concerns/views)

Docs: INSTALL_NOTES, RESEED_WORKFLOW, CONSOLE_TRICKS

Checklists: ARTICLE_SOURCE_CHECKLIST, SOLDIER_CHECKLIST, RELATIONS_CHECKLIST

Sample routes at config/ROUTES_SAMPLE.rb (from core)
""",
"README_UNIFIED.txt": f"""Unified Mega Bundle — built {today}

This includes the explicit CORE v2 code and fresh docs/checklists.
If a previous bundle was missing files, this one stands alone.

Start with INSTALL_NOTES.md.