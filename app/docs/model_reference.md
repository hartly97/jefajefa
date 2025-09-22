Model-by-model checklist

Use this as your “includes + key associations” reference. I’m marking Citable / Categorizable as Yes/No based on your note that almost every model should be categorizable.

Soldier

include Citable → Yes

include Categorizable → Yes

Belongs: cemetery (optional)

Has many: awards, citations, soldier_medals

Through: medals (through soldier_medals)

(Optional) Through Categories filtered helpers: war_categories, battle_categories

Article

include Citable → Yes

include Categorizable → Yes

Has many: citations

War

include Citable → Yes

include Categorizable → Yes

Has many: (your choice) battles (if you keep Battle model)

Alternative: treat wars as Category with category_type: "war" (then no has_many :battles required)

Battle

include Citable → Yes

include Categorizable → Yes

Belongs to: war (optional) if using the Battle model (hybrid mode)

Alternative: treat battles as Category with category_type: "battle"

Cemetery

include Citable → No (usually not cited directly)

include Categorizable → Yes (locations/regions/etc.)

Has many: soldiers

Award (NOT a medal)

include Citable → No (unless you want to footnote awards)

include Categorizable → Yes (e.g., civic, academic, service)

Belongs to: soldier

Medal

include Citable → No (usually no)

include Categorizable → Yes (if you want to group medals; otherwise No)

Has many: soldier_medals; through: soldiers

SoldierMedal (join)

include Citable → No

include Categorizable → No

Belongs to: soldier, medal

Columns: year (int), note (text)

Source

include Citable → No (Source is what’s cited, not a citer)

include Categorizable → Yes (source types, repositories, eras)

Has many: citations (dependent: restrict_with_error or nullify)

Optional counters: citations_count (if you enabled counter_cache)

Citation

include Citable → No (it is the citation)

include Categorizable → No

Belongs to: source, citable (polymorphic)

Locator fields live here (e.g., pages, quote, note)

Category

include Citable → No

include Categorizable → No

Scopes: wars, battles, awards, cemeteries, census, medals, soldiers, sources (as you like)

Has many: categorizations

Categorization

include Citable → No

include Categorizable → No

Belongs to: category, categorizable (polymorphic)

Involvement (generic link; optional if you go “categories-only”)

include Citable → No

include Categorizable → No

Belongs to: participant (poly), involvable (poly)

Uniqueness index across the 4 keys

Relation (only if you use from/to typed relationships)

include Citable → No

include Categorizable → No

Belongs to: from (poly), to (poly)

If you want Categorizable nearly everywhere (your note: “award, cemetery, census, medal, soldier, war, source”), you can safely add include Categorizable to those models; it won’t hurt, and you can use scopes like Category.wars, Category.battles, etc., to keep the Soldier form simple.