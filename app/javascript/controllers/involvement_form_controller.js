// app/javascript/controllers/involvement_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form", "list",
    "participantId", "role", "year", "note",
    "search", "suggest" // optional soldier search
  ]

  connect() {
    // optional typeahead wiring if search/suggest exist
    if (this.hasSearchTarget && this.hasSuggestTarget) {
      this._onSearchInput = this.onSearchInput.bind(this)
      this._onSearchChange = this.onSearchChange.bind(this)
      this.searchTarget.addEventListener("input", this._onSearchInput)
      this.searchTarget.addEventListener("change", this._onSearchChange)
    }
  }

  disconnect() {
    if (this._onSearchInput)  this.searchTarget.removeEventListener("input", this._onSearchInput)
    if (this._onSearchChange) this.searchTarget.removeEventListener("change", this._onSearchChange)
  }
 // called by: data-action="click->involvement-form#add"
    // uses dataset from the form container:
    //   this.formTarget.dataset.involvableType / involvableId
  async add(event) {
    event.preventDefault()
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const body = {
      involvement: {
        participant_id: this.participantIdTarget.value,
        involvable_type: this.formTarget.dataset.involvableType,
        involvable_id:   this.formTarget.dataset.involvableId,
        role: this.roleTarget.value,
        year: this.yearTarget.value,
        note: this.noteTarget.value
      }
    }

    const res = await fetch("/involvements.json", {
      method: "POST",
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
      if (this.hasSuggestTarget)      this.suggestTarget.innerHTML = ""
    } else {
      const err = await res.json().catch(() => ({}))
      alert((err.errors && err.errors.join(", ")) || "Could not add involvement.")
    }
  }

  async remove(event) {
    event.preventDefault()
    const id = event.params.id // from data-involvement-form-id-param
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const res = await fetch(`/involvements/${id}.json`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": token, "Accept": "application/json" }
    })
    if (res.status === 204) {
      this.element.querySelector(`[data-involvement-row="${id}"]`)?.remove()
    } else {
      alert("Could not remove involvement.")
    }
  }

  appendRow(inv) {
    const li = document.createElement("li")
    li.dataset.involvementRow = inv.id
    li.className = "mb-2"

    // Prefer server-provided paths; fall back to naive path if needed
    const participantLink = inv.participant_path
      ? `<a href="${this.escape(inv.participant_path)}">${this.escape(inv.participant_label)}</a>`
      : `<a href="/${this.escape(inv.participant_type.toLowerCase())}s/${this.escape(inv.participant_id)}">${this.escape(inv.participant_label)}</a>`

    const bits = [participantLink]
    if (inv.role) bits.push(` — <strong>${this.escape(inv.role)}</strong>`)
    if (inv.year) bits.push(` (${this.escape(inv.year)})`)
    if (inv.note) bits.push(` — <em>${this.escape(inv.note)}</em>`)
    bits.push(` <button data-action="involvement-form#remove" data-involvement-form-id-param="${inv.id}" class="btn btn-sm btn-outline-danger ms-2">Remove</button>`)
    li.innerHTML = bits.join("")
    this.listTarget.appendChild(li)
  }

  // --- optional soldier search (uses SoldiersController#search) ---
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
    const option = Array.from(this.suggestTarget.children).find(o => o.value === val)
    if (option && this.hasParticipantIdTarget) {
      this.participantIdTarget.value = option.getAttribute("data-id") || ""
    }
  }

  escape(s) { return String(s ?? "").replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&gt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m])) }
}








// import { Controller } from "@hotwired/stimulus"

// export default class extends Controller {
//   static targets = ["form","list","participantId","role","year","note","search","suggest"]

//   connect() {
//     this.searchTarget?.addEventListener("input", this. onSearchInput)
//     this.searchTarget?.addEventListener("change", this.onSearchChange)
//   }

//   disconnect() {
//     this.searchTarget?.removeEventListener("input", this.onSearchInput)
//     this.searchTarget?.removeEventListener("change", this.onSearchChange)
//   }

//   onSearchInput = async (e) => {
//     const q = e.target.value.trim()
//     if (q.length < 2) { this.suggestTarget.innerHTML = ""; return }
//     const res = await fetch(`/soldiers/search.json?q=${encodeURIComponent(q)}`)
//     if (!res.ok) return
//     const rows = await res.json()
//     this.suggestTarget.innerHTML = rows.map(r =>
//       `<option value="${this.escape(r.label)}" data-id="${r.id}"></option>`
//     ).join("")
//   }

//   onSearchChange = (e) => {
//     const val = e.target.value
//     const option = Array.from(this.suggestTarget.children).find(o => o.value === val)
//     if (option) this.participantIdTarget.value = option.getAttribute("data-id") || ""
//   }

//   // async add(event) {
//     event.preventDefault()
//     const token = document.querySelector('meta[name="csrf-token"]').content
//     const body = {
//       involvement: {
//         participant_id: this.participantIdTarget.value,
//         involvable_type: this.formTarget.dataset.involvableType,
//         involvable_id: this.formTarget.dataset.involvableId,
//         role: this.roleTarget.value,
//         year: this.yearTarget.value,
//         note: this.noteTarget.value
//       }
//     }
//     // const res = await fetch("/involvements.json", {
//       method: "POST",
//       headers: { "Content-Type": "application/json", "X-CSRF-Token": token, "Accept": "application/json" },
//       body: JSON.stringify(body)
//     })
//     if (res.ok) {
//       const inv = await res.json()
//       this.appendRow(inv)
//       this.formTarget.reset()
//       this.participantIdTarget.value = ""
//       this.suggestTarget.innerHTML = ""
//     } else {
//       const err = await res.json().catch(() => ({}))
//       alert((err.errors && err.errors.join(", ")) || "Could not add involvement.")
//     }
//   }

//   // async remove(event) {
//     event.preventDefault()
//     const id = event.params.id
//     const token = document.querySelector('meta[name="csrf-token"]').content
//     const res = await fetch(`/involvements/${id}.json`, {
//       method: "DELETE",
//       headers: { "X-CSRF-Token": token, "Accept": "application/json" }
//     })
//     if (res.status === 204) {
//       this.element.querySelector(`[data-involvement-row="${id}"]`)?.remove()
//     } else {
//       alert("Could not remove involvement.")
//     }
//   }

//   // appendRow(inv) {
//     const li = document.createElement("li")
//     li.dataset.involvementRow = inv.id
//     li.className = "mb-2"
//     const bits = []
//     bits.push(`<a href="/${inv.participant_type.toLowerCase()}s/${inv.participant_id}">${this.escape(inv.participant_label)}</a>`)
//     if (inv.role) bits.push(` — <strong>${this.escape(inv.role)}</strong>`)
//     if (inv.year) bits.push(` (${this.escape(inv.year)})`)
//     if (inv.note) bits.push(` — <em>${this.escape(inv.note)}</em>`)
//     bits.push(` <button data-action="involvement-form#remove" data-involvement-form-id-param="${inv.id}" class="btn btn-sm btn-outline-danger ms-2">Remove</button>`)
//     li.innerHTML = bits.join("")
//     this.listTarget.appendChild(li)
//   }

//   escape(s) {
//     return String(s ?? "").replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]))
//   }
// }
