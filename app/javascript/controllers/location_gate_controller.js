import { Controller } from "@hotwired/stimulus"

// Requests browser geolocation and POSTs it to the proximity endpoint.
// On success, reloads the page so the server-rendered feed takes over.
export default class extends Controller {
  static targets = ["allowButton", "denied"]
  static values  = { url: String }

  requestLocation() {
    if (!("geolocation" in navigator)) {
      this.showDenied()
      return
    }

    this.allowButtonTarget.disabled = true

    navigator.geolocation.getCurrentPosition(
      (pos) => this.submit(pos.coords.latitude, pos.coords.longitude),
      ()    => this.showDenied(),
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 300000 }
    )
  }

  async submit(latitude, longitude) {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const response = await fetch(this.urlValue, {
      method: "POST",
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": token
      },
      body: JSON.stringify({ latitude, longitude })
    })

    if (response.ok) {
      window.location.reload()
    } else {
      this.showDenied()
    }
  }

  showDenied() {
    this.allowButtonTarget.disabled = false
    this.deniedTarget.hidden = false
  }
}
