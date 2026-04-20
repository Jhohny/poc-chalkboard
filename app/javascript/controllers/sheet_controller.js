import { Controller } from "@hotwired/stimulus"

// Minimal bottom-sheet open/close for the composer.
export default class extends Controller {
  static targets = ["panel", "fab"]

  open() {
    this.panelTarget.hidden = false
    if (this.hasFabTarget) this.fabTarget.hidden = true
    this.panelTarget.querySelector("textarea")?.focus()
  }

  close() {
    this.panelTarget.hidden = true
    if (this.hasFabTarget) this.fabTarget.hidden = false
  }
}
