// app/javascript/controllers/involvement_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form", "list",
    "participantId", "role", "year", "note",
    "search", "suggest",
    "addButton"
  ]

  connect() {
    // Wire search events if the search input + datalist exist
    if (this.hasSearchTarget && this.hasSuggestTarget) {
      this._onSearchInput = this.onSearchInput.bind(this)
      this._onSearchChange = this.onSearchChange.bind(this)
      this.searchTarget.addEventListener("input", this._onSearchInput)
      this.searchTarget.addEventListener("change", this._onSearchChange)
    }
    // Set initial button state
    this.toggleAdd()
  }

  disconnect() {
    if (this._onSearchInput)  this.searchTarget.removeEventListener("input", this._onSearchInput)
    if (this._onSearchChange) this.searchTarget.removeEventListener("change", this._onSearchChange)
  }

  // --- Add / Remove ---------------------------------------------------------

  async add(event) {
    event.preventDefault()

    const box = this.formTarget?.dataset || {}
    const involvableType = box.involvableType
    const involvableId   = box.involvableId
    const participantId  = this.hasParticipantIdTarget ? this.participantIdTarget.value.trim() : ""

    if (!involvableType || !involvableId) {
      alert("Pick a target record first (this page should provide it).")
      return
    }
    if (!participantId) {
      alert("Choose a soldier from the suggestions so I know who to add.")
      return
    }

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const body = {
      involvement: {
        participant_id:  participantId,
        involvable_type: involvableType,
        involvable_id:   involvableId,
        role: this.roleTarget?.value,
        year: this.yearTarget?.value,
        note: this.noteTarget?.value
      }
    }

    const res = await fetch("/involvements.json", {
      method: "POST",
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token,
        "Accept": "application/json"
      },
      body: JSON.stringify(body)
    })

    if (res.ok) {
      const inv = await res.json()
      this.appendRow(inv)
      this.formTarget.reset()
      if (this.hasParticipantIdTarget) this.participantIdTarget.value = ""
      if (this.hasSuggestTarget) this.suggestTarget.innerHTML = ""
      this.toggleAdd()
    } else {
      const err = await res.json().catch(() => ({}))
      alert((err.errors && err.errors.join(", ")) || "Could not add involvement.")
    }
  }

  async remove(event) {
    event.preventDefault()
    const id = event.params.id
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const res = await fetch(`/involvements/${id}.json`, {
      method: "DELETE",
      credentials: "same-origin",
      headers: { "X-CSRF-Token": token, "Accept": "application/json" }
    })
    if (res.status === 204) {
      this.element.querySelector(`[data-involvement-row="${id}"]`)?.remove()
    } else {
      alert("Could not remove involvement.")
    }
  }

  // --- Search (datalist) -----------------------------------------------------

  async onSearchInput(e) {
    const q = e.target.value.trim()

    if (q.length < 2) {
      if (this.hasSuggestTarget) this.suggestTarget.innerHTML = ""
      if (this.hasParticipantIdTarget) this.participantIdTarget.value = ""
      this.toggleAdd()
      return
    }

    const res = await fetch(`/soldiers/search.json?q=${encodeURIComponent(q)}`, {
      credentials: "same-origin",
      headers: { Accept: "application/json" }
    })
    if (!res.ok) return
    const rows = await res.json()

    if (this.hasSuggestTarget) {
      this.suggestTarget.innerHTML = rows.map(r =>
        `<option value="${this.escape(r.label)}" data-id="${r.id}"></option>`
      ).join("")
    }

    // If there’s exactly one clear match, prime the hidden id
    if (this.hasParticipantIdTarget) {
      if (rows.length === 1) {
        this.participantIdTarget.value = rows[0].id
      } else {
        this.participantIdTarget.value = ""
      }
    }
    this.toggleAdd()
  }

  onSearchChange(e) {
    const val = e.target.value
    if (!this.hasSuggestTarget || !this.hasParticipantIdTarget) return
    const opt = Array.from(this.suggestTarget.children).find(o => o.value === val)
    this.participantIdTarget.value = opt ? (opt.getAttribute("data-id") || "") : ""
    this.toggleAdd()
  }

  // --- UI helpers ------------------------------------------------------------

  toggleAdd() {
    const btn = this.addButtonTarget
    if (!btn) return
    const ok = this.hasParticipantIdTarget && this.participantIdTarget.value.trim() !== ""
    btn.disabled = !ok
    btn.classList.toggle("disabled", !ok)
    btn.title = ok ? "" : "Choose a soldier from the suggestions first"
  }

  appendRow(inv) {
    const li = document.createElement("li")
    li.dataset.involvementRow = inv.id
    li.className = "mb-2"

    const participantLink = inv.participant_path
      ? `<a href="${this.escape(inv.participant_path)}">${this.escape(inv.participant_label)}</a>`
      : `<a href="/${this.escape(inv.participant_type.toLowerCase())}s/${this.escape(inv.participant_id)}">${this.escape(inv.participant_label)}</a>`

    const bits = [participantLink]
    if (inv.role) bits.push(` — <strong>${this.escape(inv.role)}</strong>`)
    if (inv.year) bits.push(` (${this.escape(inv.year)})`)
    if (inv.note) bits.push(` — <em>${this.escape(inv.note)}</em>`)
    bits.push(
      ` <button data-action="involvement-form#remove" data-involvement-form-id-param="${inv.id}" class="btn btn-sm btn-outline-danger ms-2">Remove</button>`
    )
    li.innerHTML = bits.join("")
    this.listTarget.appendChild(li)
  }

  escape(s) {
    return String(s ?? "").replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]))
  }
}
