#!/usr/bin/env bash
set -euo pipefail

echo "==> Creating directories…"
mkdir -p app/javascript/controllers
mkdir -p docs
mkdir -p db

echo "==> Writing app/javascript/application.js"
cat > app/javascript/application.js <<'EOF'
// app/javascript/application.js
import "@hotwired/turbo-rails"
import "./controllers"
// If you previously imported other JS (UJS, etc.), bring it here too.
EOF

echo "==> Writing app/javascript/controllers/index.js"
cat > app/javascript/controllers/index.js <<'EOF'
// app/javascript/controllers/index.js
import { Application } from "@hotwired/stimulus"

import CitationsController from "./citations_controller"
import SourcePickerController from "./source_picker_controller"

window.Stimulus = Application.start()

Stimulus.register("citations",     CitationsController)
Stimulus.register("source-picker", SourcePickerController)
EOF

echo "==> Writing app/javascript/controllers/citations_controller.js"
cat > app/javascript/controllers/citations_controller.js <<'EOF'
// app/javascript/controllers/citations_controller.js
import { Controller } from "@hotwired/stimulus"

// Handles dynamic add/remove of <%= f.fields_for :citations %> blocks.
// Expected in the form:
//   data-controller="citations"
//   data-citations-index-value="<%= @record.citations.size %>"
// Targets:
//   data-citations-target="list"     — container where blocks are appended
//   data-citations-target="template" — <template> with NEW_RECORD placeholder
// Each block wrapper should have: data-citations-wrapper
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
EOF

echo "==> Writing app/javascript/controllers/source_picker_controller.js"
cat > app/javascript/controllers/source_picker_controller.js <<'EOF'
// app/javascript/controllers/source_picker_controller.js
import { Controller } from "@hotwired/stimulus"

// Powers the Source <select>, "Recent", autocomplete, and the inline new Source form.
// Targets inside each citation block:
//   data-source-picker-target="select"  — <select> for :source_id
//   data-source-picker-target="query"   — <input> used for autocomplete
//   data-source-picker-target="results" — <ul> we fill with matches
//   data-source-picker-target="newForm" — collapsible inline Source form
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
          `<li class="list-group-item" data-id="\${i.id}" data-title="\${this._escape(i.title)}">\${this._escape(i.title)}</li>`
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
    this.selectTarget.innerHTML = `<option value="\${id}" selected>\${this._escape(title)}</option>`
  }

  _escape(s) {
    return (s || "").replace(/[&<>"']/g, c => (
      {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]
    ))
  }
}
EOF

echo "==> Writing docs/soldiers_crud_checklist.md"
cat > docs/soldiers_crud_checklist.md <<'EOF'
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
EOF

echo "==> Writing db/seeds_soldier_demo.rb"
cat > db/seeds_soldier_demo.rb <<'EOF'
# Run with:
#   bin/rails runner db/seeds_soldier_demo.rb

ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.logger.level = Logger::INFO

def say(msg) = puts "\n==> #{msg}"

say "Ensuring base records exist (Medal, Cemetery, Source)..."

medal = Medal.find_or_create_by!(name: "Purple Heart") { |m| m.slug = "purple-heart" }
cemetery = (defined?(Cemetery) ? (Cemetery.first || Cemetery.create!(name: "Mount Auburn Cemetery", slug: "mount-auburn-cemetery")) : nil)
source = Source.find_or_create_by!(title: "Boston Gazette") { |s| s.year = "1750" }

say "Creating a demo Soldier with nested Award, Medal, and Citation..."

soldier = Soldier.create!(
  first_name: "Test",
  last_name:  "User",
  unit: "Infantry",
  branch_of_service: "Army",
  cemetery: cemetery
)

soldier.awards.create!(name: "Community Service", country: "USA", year: 1950, note: "Local recognition")
soldier.soldier_medals.create!(medal: medal, year: 1945, note: "Wartime commendation")
soldier.citations.create!(source: source, pages: "12–13", note: "Newspaper blurb")

say "Done."
say "Soldier:  #{soldier.id} — #{[soldier.first_name, soldier.last_name].compact.join(' ')}"
say "Awards:   #{soldier.awards.count}"
say "Medals:   #{soldier.medals.count} (via SoldierMedals: #{soldier.soldier_medals.count})"
say "Citations #{soldier.citations.count} (Sources: #{soldier.sources.count})"
EOF

echo "==> Writing README_RUN.md"
cat > README_RUN.md <<'EOF'
# Soldiers CRUD Mini-Bundle

## Files
- docs/soldiers_crud_checklist.md
- db/seeds_soldier_demo.rb
- README_RUN.md

## Run the demo seed
bin/rails runner db/seeds_soldier_demo.rb
EOF

echo "==> All done."
echo "Restart your dev server and you’re set."
