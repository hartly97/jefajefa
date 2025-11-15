import { Application } from "@hotwired/stimulus"

import CitationsController from "./citations_controller"
import SourcePickerController from "./source_picker_controller"

window.Stimulus = Application.start()

Stimulus.register("citations",      CitationsController)
Stimulus.register("source-picker",  SourcePickerController)
