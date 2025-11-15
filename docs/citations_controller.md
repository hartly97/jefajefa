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
