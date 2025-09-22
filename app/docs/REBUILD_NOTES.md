# Rebuild Notes (v8 full)

Includes: concerns, models, migrations, full CRUD controllers for Articles, Categories, Soldiers, Cemeteries, Sources (with reverse citations), Wars, Battles, Medals; CategorizationsController; InvolvementsController; seeds.

## Quick Start
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
bin/rails s

## Involvements UI
War/Battle/Medal `show` pages list Soldier involvements and include a simple form to add a Soldier with role/year/note. InvolvementsController handles create/destroy.

## Sources
Source `show` lists reverse citations and provides a form to cite any record (choose citable type + ID, pages/quote/note).


### v9 additions
- Added **search pickers**:
  - `/soldiers/search?q=...` used by Soldier pickers on War/Battle/Medal pages.
  - `/lookups/citables?type=Model&q=...` for generic citable search on Source show page.
- Inline JS enhances forms with a datalist dropdown and auto-fills hidden ID fields.
