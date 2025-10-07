import { Controller } from "@hotwired/stimulus"

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

