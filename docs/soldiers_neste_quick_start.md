README_RUN.md
# Soldiers Nested Quickstart (Mini Bundle)

This gives you:
- `docs/soldiers_crud_checklist.md` — what to verify
- `db/seeds_soldier_demo.rb` — a seed script you can run with `rails runner`

## How to use

1) Save the files into your app at:
docs/soldiers_crud_checklist.md
db/seeds_soldier_demo.rb

2) Run the seed script (non-destructive, idempotent):
```bash
bin/rails runner db/seeds_soldier_demo.rb
3.	Open the UI
•	Visit /soldiers → create/edit a Soldier with nested Awards/Medals/Citations.
•	Confirm autocomplete works at /sources/autocomplete?q=ha.
If anything errors, use the checklist to see what’s missing.

---

# db/seeds_soldier_demo.rb
```ruby
# Usage:
#   bin/rails runner db/seeds_soldier_demo.rb
# Creates a demo Soldier with Award, Medal (via SoldierMedal), and a Citation+Source.

ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.logger.level = Logger::INFO

def say(msg) = puts "\n==> #{msg}"

say "Ensuring base records exist (Medal, Cemetery, Source)..."

medal = Medal.find_or_create_by!(name: "Purple Heart") do |m|
  m.slug = "purple-heart"
end

cemetery = if defined?(Cemetery)
  Cemetery.first || Cemetery.create!(name: "Mount Auburn Cemetery", slug: "mount-auburn-cemetery")
end

source = Source.find_or_create_by!(title: "Boston Gazette") do |s|
  s.year = "1750"
end

say "Creating a demo Soldier with nested Award, Medal, and Citation..."

soldier = Soldier.create!(
  first_name: "Test",
  last_name:  "User",
  unit: "Infantry",
  branch_of_service: "Army",
  cemetery: cemetery
)

soldier.awards.create!(
  name: "Community Service",
  country: "USA",
  year: 1950,
  note: "Local recognition"
)

soldier.soldier_medals.create!(
  medal: medal,
  year: 1945,
  note: "Wartime commendation"
)

soldier.citations.create!(
  source: source,
  pages: "12–13",
  note: "Newspaper blurb"
)

say "Done."
say "Soldier:  #{soldier.id} — #{[soldier.first_name, soldier.last_name].compact.join(' ')}"
say "Awards:   #{soldier.awards.count}"
say "Medals:   #{soldier.medals.count} (via SoldierMedals: #{soldier.soldier_medals.count})"
say "Citations #{soldier.citations.count} (Sources: #{soldier.sources.count})"
 
docs/soldiers_crud_checklist.md
# Soldiers CRUD + Nested (Awards / Medals / Citations) — Quick Checklist

Run these to verify wiring after adding the nested form + controller bits.

## 1) Routes
```bash
bin/rails routes -g "^soldiers#"
bin/rails routes -g "^involvements#"
bin/rails routes -g "^sources#autocomplete"
bin/rails routes -g regenerate_slug
Expect Soldiers standard CRUD, search (collection), regenerate_slug (member); involvements#create/destroy; sources#autocomplete.
2) Model wiring (recap)
•	Soldier:
o	has_many :awards, dependent: :destroy, inverse_of: :soldier
o	accepts_nested_attributes_for :awards, allow_destroy: true
o	has_many :soldier_medals, dependent: :destroy, inverse_of: :soldier
o	has_many :medals, through: :soldier_medals
o	accepts_nested_attributes_for :soldier_medals, allow_destroy: true
o	has_many :citations, as: :citable, dependent: :destroy, inverse_of: :citable
o	accepts_nested_attributes_for :citations, allow_destroy: true
•	Award belongs_to Soldier (+ optional Citable/Categorizable/Sluggable if you included them).
•	SoldierMedal belongs_to Soldier and Medal.
•	Medal has_many SoldierMedals; has_many Soldiers through SoldierMedals.
•	Citation belongs_to Source; polymorphic citable; accepts_nested_attributes_for :source.
3) Strong params (SoldiersController)
Ensure:
•	Basics (+ :unit, :branch_of_service, :cemetery_id, { category_ids: [] })
•	awards_attributes: [:id, :name, :country, :year, :note, :_destroy]
•	soldier_medals_attributes: [:id, :medal_id, :year, :note, :_destroy]
•	citations_attributes: [:id, :source_id, :_destroy, :page, :pages, :folio, :column, :line_number, :record_number, :locator, :image_url, :image_frame, :roll, :enumeration_district, :quote, :note, { source_attributes: [:id, :title, :author, :publisher, :year, :url, :details, :repository, :link_url] }]
4) Form smoke test
•	New → add one Award, one Medal, one Citation (optionally create a new Source inline) → Create → Show.
•	Edit → add/remove rows → Update.
5) Console smoke test
s = Soldier.first || Soldier.create!(first_name: "Test", last_name: "User")
m = Medal.first  || Medal.create!(name: "Purple Heart", slug: "purple-heart")
s.awards.create!(name: "Community Service", country: "USA", year: 1950)
s.soldier_medals.create!(medal: m, year: 1945)
src = Source.first || Source.create!(title: "Boston Gazette", year: "1750")
s.citations.create!(source: src, pages: "12–13", note: "Snippet")
[s.reload.awards.size, s.soldier_medals.size, s.citations.size, s.sources.size]
Expect: [1, 1, 1, 1].
6) JS sanity
•	No 404s for citations_controller.js and source_picker_controller.js.
•	Typing in Source search hits /sources/autocomplete?q=... and returns JSON.

---

If you want, I can also paste the exact `citations_controller.js` and `source_picker_controller.js` you’re using so everything is in one place.
You said:
please
ChatGPT said:
perfect — here are the two Stimulus controllers exactly as we’ve been wiring the views to use. Drop them into your app and restart dev if you’re running via bin/dev.
app/javascript/controllers/citations_controller.js
import { Controller } from "@hotwired/stimulus"

// Handles dynamic add/remove of <%= f.fields_for :citations %> blocks.
// Expects:
//   data-controller="citations"
//   data-citations-index-value="<%= @record.citations.size %>"
// Targets:
//   data-citations-target="list"     — where new blocks get appended
//   data-citations-target="template" — a <template> containing a NEW_RECORD placeholder
// Wrapper each block with: data-citations-wrapper
export default class extends Controller {
  static targets = ["list", "template"]
  static values = { index: Number }

  connect() {
    if (this.indexValue == null) this.indexValue = this._nextIndex()
  }

  add(event) {
    event.preventDefault()
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", this.indexValue)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.indexValue++
  }

  remove(event) {
    event.preventDefault()
    const wrapper = event.currentTarget.closest("[data-citations-wrapper]")
    const destroyField = wrapper?.querySelector("input[name*='[_destroy]']")
    if (destroyField) {
      destroyField.value = "1"
      wrapper.style.display = "none"
    } else {
      wrapper?.remove()
    }
  }

  _nextIndex() {
    return this.listTarget.querySelectorAll("[data-citations-wrapper]").length
  }
}
app/javascript/controllers/source_picker_controller.js
import { Controller } from "@hotwired/stimulus"

// Powers the Source <select>, "Recent", autocomplete, and the inline new Source form.
// Expects data targets in the citation block:
//   data-source-picker-target="select"  — the <select> for :source_id
//   data-source-picker-target="query"   — the <input> used to autocomplete
//   data-source-picker-target="results" — the <ul> we fill with matches
//   data-source-picker-target="newForm" — the collapsible inline form
export default class extends Controller {
  static targets = ["query", "results", "select", "newForm"]

  pick(event) {
    const id = event.target.value
    if (!id) return
    const title = event.target.options[event.target.selectedIndex]?.textContent || `Source #${id}`
    this._setSelected(id, title)
    event.target.selectedIndex = 0
  }

  autocomplete() {
    const q = this.hasQueryTarget ? this.queryTarget.value.trim() : ""
    clearTimeout(this._t)
    if (!q || q.length < 2) {
      if (this.hasResultsTarget) this.resultsTarget.innerHTML = ""
      return
    }
    this._t = setTimeout(async () => {
      try {
        const res = await fetch(`/sources/autocomplete?q=${encodeURIComponent(q)}`)
        if (!res.ok) return
        const items = await res.json()
        if (!this.hasResultsTarget) return
        this.resultsTarget.innerHTML = items.map(i =>
          `<li class="list-group-item" data-id="${i.id}" data-title="${this._escape(i.title)}">${this._escape(i.title)}</li>`
        ).join("")
        this.resultsTarget.querySelectorAll("li").forEach(li => {
          li.addEventListener("click", () => {
            this._setSelected(li.dataset.id, li.dataset.title)
            this.resultsTarget.innerHTML = ""
            if (this.hasQueryTarget) this.queryTarget.value = li.dataset.title
          })
        })
      } catch (_) { /* ignore */ }
    }, 200)
  }

  toggleNewForm() {
    if (!this.hasNewFormTarget) return
    const el = this.newFormTarget
    el.style.display = (el.style.display === "none" || !el.style.display) ? "block" : "none"
  }

  clearSelectIfTyped() {
    if (this.hasSelectTarget) {
      this.selectTarget.innerHTML = '<option value="" selected></option>'
    }
  }

  _setSelected(id, title) {
    if (!this.hasSelectTarget) return
    this.selectTarget.innerHTML = `<option value="${id}" selected>${this._escape(title)}</option>`
  }

  _escape(s) {
    return (s || "").replace(/[&<>"']/g, c => (
      {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]
    ))
  }
}
quick sanity checks:
•	both files saved under app/javascript/controllers/…
•	your Stimulus setup imports them (usually application.js has import "./controllers").
•	in your citation block you have:
o	data-controller="citations"
o	a <div data-citations-target="list">…</div>
o	a <template data-citations-target="template">…</template>
o	buttons with data-action="citations#add" and data-action="citations#remove"
o	for the source picker: data-controller="source-picker" on the citation wrapper plus the targets used in the partials we built.
Want me to also paste the tiny application.js Stimulus bootstrap just to be sure it’s loading?
