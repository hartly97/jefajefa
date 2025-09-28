// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"// <- ensures citations_controller gets bundled
// this line ensures index.js runs
import * as bootstrap from "bootstrap"


import "trix"
import "@rails/actiontext"
