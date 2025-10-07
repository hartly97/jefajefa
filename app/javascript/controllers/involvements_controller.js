// app/javascript/controllers/involvement_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "list", "participantId", "role", "year", "note"]

  async add(event) {
    event.preventDefault()
    const token = document.querySelector('meta[name="csrf-token"]').content
    const body = {
      involvement: {
        participant_id: this.participantIdTarget.value,
        involvable_type: this.formTarget.dataset.involvableType,
        involvable_id: this.formTarget.dataset.involvableId,
        role: this.roleTarget.value,
        year: this.yearTarget.value,
        note: this.noteTarget.value
      }
    }
    const res = await fetch("/involvements.json", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token, "Accept": "application/json" },
      body: JSON.stringify(body)
    })
    if (res.ok) {
      const inv = await res.json()
      this.appendRow(inv)
      this.formTarget.reset()
      this.participantIdTarget.value = ""
    } else {
      const err = await res.json().catch(() => ({}))
      alert((err.errors && err.errors.join(", ")) || "Could not add involvement.")
    }
  }

  async remove(event) {
    event.preventDefault()
    const id = event.params.id // from data-action param
    const token = document.querySelector('meta[name="csrf-token"]').content
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
    const bits = []
    bits.push(`<a href="/${inv.participant_type.toLowerCase()}s/${inv.participant_id}">${inv.participant_label}</a>`)
    if (inv.role) bits.push(` — <strong>${this.escape(inv.role)}</strong>`)
    if (inv.year) bits.push(` (${this.escape(inv.year)})`)
    if (inv.note) bits.push(` — <em>${this.escape(inv.note)}</em>`)
    bits.push(` <button data-action="involvement-form#remove" data-involvement-form-id-param="${inv.id}" class="btn btn-sm btn-outline-danger ms-2">Remove</button>`)
    li.innerHTML = bits.join("")
    this.listTarget.appendChild(li)
  }

  escape(s) { return String(s).replace(/[&<>"']/g, m => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m])) }
}
