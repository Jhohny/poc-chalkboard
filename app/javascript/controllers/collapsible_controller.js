import { Controller } from "@hotwired/stimulus"

// Shows a floating "Write" FAB on mobile once the composer scrolls out of view.
// Does nothing on desktop (lg+).
export default class extends Controller {
  static targets = ["panel", "fab"]

  connect() {
    if (window.innerWidth >= 1024) return

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this.fabTarget.classList.add("opacity-0", "pointer-events-none")
          } else {
            this.fabTarget.classList.remove("opacity-0", "pointer-events-none")
          }
        })
      },
      { threshold: 0.1 }
    )

    this.observer.observe(this.panelTarget)
  }

  disconnect() {
    this.observer?.disconnect()
  }

  expand() {
    this.panelTarget.scrollIntoView({ behavior: "smooth", block: "start" })
  }
}
