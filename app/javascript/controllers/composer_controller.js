import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter"]
  static values = { limit: Number }

  connect() {
    this.updateCounter()
  }

  updateCounter() {
    const remaining = this.limitValue - this.inputTarget.value.length
    this.counterTarget.textContent = remaining
  }
}
