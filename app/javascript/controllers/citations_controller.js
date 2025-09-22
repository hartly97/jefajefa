import { Controller } from "@hotwired/stimulus"

data-controller="citations"
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
    const destroyField = wrapper.querySelector("input[name*='[_destroy]']")
    if (destroyField) {
      destroyField.value = "1"
      wrapper.style.display = "none"
    } else {
      wrapper.remove()
    }
  }

  _nextIndex() {
    const items = this.listTarget.querySelectorAll("[data-citations-wrapper]")
    return items.length
  }
}

<div data-controller="citations"
     data-citations-index-value="<%= @record.citations.size %>">

  <div data-citations-target="list">
    <% f.fields_for :citations do |cf| %>
      <div data-citations-wrapper>
        <%= render "citations/fields", f: cf, sources: Source.order(:title) %>
      </div>
    <% end %>
  </div>

#   <template data-citations-target="template">
#     <div data-citations-wrapper>
#       <%= f.fields_for :citations, Citation.new, child_index: "NEW_RECORD" do |cf| %>
#         <%= render "citations/fields", f: cf, sources: Source.order(:title) %>
#       <% end %>
#     </div>
#   </template>

#   <p>
#     <button type="button" data-action="citations#add">Add citation</button>
#   </p>
# </div>

