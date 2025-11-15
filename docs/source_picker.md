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
