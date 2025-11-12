
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form","list","search","suggest","soldierId",
    "firstName","middleName","lastName",
    "birthDate","birthPlace","deathDate","deathPlace",
    "inscription","section","plot","marker","note"
  ]

  connect() {
    this.onSearchInput  = this.onSearchInput?.bind(this)
    this.onSearchChange = this.onSearchChange?.bind(this)
    this.searchTarget?.addEventListener("input", this.onSearchInput)
    this.searchTarget?.addEventListener("change", this.onSearchChange)
  }

  disconnect() {
    this.searchTarget?.removeEventListener("input", this.onSearchInput)
    this.searchTarget?.removeEventListener("change", this.onSearchChange)
  }

  async onSearchInput(e) {
    const q = e.target.value.trim()
    if (q.length < 2) { this.suggestTarget.innerHTML = ""; return }
    const res = await fetch(`/soldiers/search.json?q=${encodeURIComponent(q)}`)
    if (!res.ok) return
    const rows = await res.json()
    this.suggestTarget.innerHTML = rows.map(r =>
      `<option value="${this.escape(r.label)}" data-id="${r.id}"></option>`
    ).join("")
  }

  onSearchChange(e) {
    const val = e.target.value
    const opt = Array.from(this.suggestTarget.children).find(o => o.value === val)
    this.soldierIdTarget.value = opt ? (opt.getAttribute("data-id") || "") : ""
  }

  async add() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const body = {
      burial: {
        cemetery_id: this.formTarget.dataset.cemeteryId,
        first_name:  this.firstNameTarget?.value,
        middle_name: this.middleNameTarget?.value,
        last_name:   this.lastNameTarget?.value,
        birth_date:  this.birthDateTarget?.value,
        birth_place: this.birthPlaceTarget?.value,
        death_date:  this.deathDateTarget?.value,
        death_place: this.deathPlaceTarget?.value,
        inscription: this.inscriptionTarget?.value,
        section:     this.sectionTarget?.value,
        plot:        this.plotTarget?.value,
        marker:      this.markerTarget?.value,
        note:        this.noteTarget?.value
      },
      soldier_id: this.soldierIdTarget?.value || null
    }

    const res = await fetch("/burials.json", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token, "Accept": "application/json" },
      body: JSON.stringify(body)
    })
    if (!res.ok) { alert("Could not add burial."); return }
    const b = await res.json()
    this.appendRow(b)
    this.formTarget.reset()
    if (this.suggestTarget) this.suggestTarget.innerHTML = ""
  }

  async remove(e) {
    const id = e.params.id
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const res = await fetch(`/burials/${id}.json`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": token, "Accept": "application/json" }
    })
    if (res.status === 204) {
      this.element.querySelector(`[data-burial-row="${id}"]`)?.remove()
    } else {
      alert("Could not remove burial.")
    }
  }

  appendRow(b) {
    const li = document.createElement("li")
    li.dataset.burialRow = b.id
    li.className = "mb-1"
    const bits = []
    bits.push(`<strong>${this.escape(b.name)}</strong>`)
    if (b.inscription) bits.push(` — <em>${this.escape(b.inscription)}</em>`)
    if (b.location)    bits.push(` — ${this.escape(b.location)}`)
    if (b.note)        bits.push(` — ${this.escape(b.note)}`)
    bits.push(` <button class="btn btn-sm btn-outline-danger ms-2" data-action="burial-form#remove" data-burial-form-id-param="${b.id}">Remove</button>`)
    li.innerHTML = bits.join("")
    this.listTarget.appendChild(li)
  }

  escape(s){return String(s??"").replace(/[&<>"']/g,m=>({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]))}
}
