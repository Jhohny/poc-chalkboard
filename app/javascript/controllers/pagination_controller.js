import { Turbo } from "@hotwired/turbo-rails"
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.loaded = false
    this.observer = new IntersectionObserver((entries) => {
      if (this.loaded) return

      entries.forEach((entry) => {
        if (!entry.isIntersecting) return

        this.loaded = true
        this.fetchNextPage()
      })
    }, { rootMargin: "240px" })

    this.observer.observe(this.element)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  async fetchNextPage() {
    const response = await fetch(this.urlValue, {
      headers: {
        Accept: "text/vnd.turbo-stream.html"
      },
      credentials: "same-origin"
    })

    if (!response.ok) return

    Turbo.renderStreamMessage(await response.text())
  }
}
