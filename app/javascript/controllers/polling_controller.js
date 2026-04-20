import { Turbo } from "@hotwired/turbo-rails"
import { Controller } from "@hotwired/stimulus"

// Polls the server for new nearby notes every `interval` ms while the tab
// is visible and the user has interacted in the last IDLE_MS.
export default class extends Controller {
  static values = { url: String, interval: { type: Number, default: 60000 } }

  IDLE_MS = 10 * 60 * 1000

  connect() {
    this.lastInteractionAt = Date.now()
    this.since = new Date().toISOString()

    this.interactionHandler = () => { this.lastInteractionAt = Date.now() }
    document.addEventListener("pointermove", this.interactionHandler, { passive: true })
    document.addEventListener("keydown",     this.interactionHandler)

    this.schedule()
  }

  disconnect() {
    if (this.timer) clearTimeout(this.timer)
    document.removeEventListener("pointermove", this.interactionHandler)
    document.removeEventListener("keydown",     this.interactionHandler)
  }

  schedule() {
    this.timer = setTimeout(() => this.tick(), this.intervalValue)
  }

  async tick() {
    if (this.shouldPoll()) await this.fetchUpdates()
    this.schedule()
  }

  shouldPoll() {
    if (document.visibilityState !== "visible") return false
    if (Date.now() - this.lastInteractionAt > this.IDLE_MS) return false
    return true
  }

  async fetchUpdates() {
    const url = `${this.urlValue}${this.urlValue.includes("?") ? "&" : "?"}since=${encodeURIComponent(this.since)}`
    const response = await fetch(url, {
      headers: { Accept: "text/vnd.turbo-stream.html" },
      credentials: "same-origin"
    })

    if (!response.ok) return

    this.since = new Date().toISOString()
    Turbo.renderStreamMessage(await response.text())
  }
}
