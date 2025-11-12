import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"
import "trix"
import "@rails/actiontext"

// Initialize Bootstrap tooltips globally
document.addEventListener("turbo:load", initBadgesTooltips)
document.addEventListener("DOMContentLoaded", initBadgesTooltips)

function initBadgesTooltips() {
  if (!window.bootstrap) return
  document
    .querySelectorAll('[data-bs-toggle="tooltip"]')
    .forEach(el => new bootstrap.Tooltip(el))
}
