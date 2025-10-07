import { Controller } from "@hotwired/stimulus"

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
    if (!this.hasQueryTarget || !this.hasResultsTarget) return
    const q = this.queryTarget.value.trim()
    clearTimeout(this._t)
    if (q.length < 2) { this.resultsTarget.innerHTML = ""; return }
    this._t = setTimeout(async () => {
      const res = await fetch(`/sources/autocomplete?q=${encodeURIComponent(q)}`, { headers: { "Accept": "application/json" } })
      if (!res.ok) return
      const items = await res.json()
      this.resultsTarget.innerHTML = items.map(i =>
        `<li class="list-group-item" data-id="${i.id}" data-title="${this._escape(i.title)}">${this._escape(i.title)}</li>`
      ).join("")
      this.resultsTarget.querySelectorAll("li").forEach(li => {
        li.addEventListener("click", () => {
          this._setSelected(li.dataset.id, li.dataset.title)
          this.resultsTarget.innerHTML = ""
          if (this.hasQueryTarget) this.queryTarget.value = li.dataset.title
          if (this.hasNewFormTarget) this.newFormTarget.style.display = "none"
        })
      })
    }, 200)
  }

  toggleNewForm() {
    if (!this.hasNewFormTarget) return
    const el = this.newFormTarget
    el.style.display = (el.style.display === "none" || !el.style.display) ? "block" : "none"
    if (this.hasSelectTarget && el.style.display === "block") {
      this.selectTarget.value = ""
    }
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
    return (s || "").replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]))
  }
}
