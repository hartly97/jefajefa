// app/javascript/controllers/involvement_picker_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["formBox","typeSelect","warSelect","battleSelect","cemeterySelect"]

  // 👇 tolerate target being missing; find the nearest form wrapper
  get formBoxEl() {
    return this.hasFormBoxTarget
      ? this.formBoxTarget
      : this.element.closest('[data-involvement-form-target="form"]')
  }

  connect() {
    const t = this.typeSelectTarget.value || "War"
    this.setType(t)
    const sel = this.visibleSelect(t)
    if (sel && sel.value) this.formBoxEl.dataset.involvableId = sel.value
  }

  changeType(e) {
    this.setType(e.currentTarget.value)
    this.formBoxEl.dataset.involvableId = ""
  }

  pick(e) { this.formBoxEl.dataset.involvableId = e.currentTarget.value }

  setType(t) {
    this.formBoxEl.dataset.involvableType = t
    this.typeSelectTarget.value = t
    this.toggle(this.warSelectTarget,      t === "War")
    this.toggle(this.battleSelectTarget,   t === "Battle")
    this.toggle(this.cemeterySelectTarget, t === "Cemetery")
  }

  visibleSelect(t) {
    if (t === "War") return this.warSelectTarget
    if (t === "Battle") return this.battleSelectTarget
    if (t === "Cemetery") return this.cemeterySelectTarget
  }

  toggle(el, on) { el.classList.toggle("d-none", !on) }
}
