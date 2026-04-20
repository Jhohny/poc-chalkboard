import { Controller } from "@hotwired/stimulus"

// Manages stack navigation: one card visible at a time, arrow keys and
// swipe gestures move through the deck. When the deck is exhausted, the
// end-of-stack panel (with the radius widener) is revealed.
export default class extends Controller {
  static targets = ["pile", "card", "progress", "end"]

  connect() {
    this.index = 0
    this.render()

    this.keyHandler = (event) => this.onKey(event)
    document.addEventListener("keydown", this.keyHandler)

    this.touchStart = null
    this.pileTarget.addEventListener("touchstart", (e) => this.onTouchStart(e), { passive: true })
    this.pileTarget.addEventListener("touchend",   (e) => this.onTouchEnd(e),   { passive: true })
  }

  disconnect() {
    document.removeEventListener("keydown", this.keyHandler)
  }

  cardTargetConnected(card) {
    // Inline `style="--card-rotate: ...; --card-opacity: ..."` on the server
    // would trip CSP's style-src. Read the values from data attributes and
    // apply them via JS (setProperty is permitted).
    const rotate  = card.dataset.cardRotate
    const opacity = card.dataset.cardOpacity
    if (rotate  != null) card.style.setProperty("--card-rotate",  `${rotate}deg`)
    if (opacity != null) card.style.setProperty("--card-opacity", opacity)

    this.render()
  }

  next() {
    if (this.index < this.cardTargets.length - 1) {
      this.index += 1
      this.render()
    } else {
      this.showEnd()
    }
  }

  prev() {
    if (this.index > 0) {
      this.index -= 1
      this.render()
    }
  }

  render() {
    this.cardTargets.forEach((card, i) => {
      const offset = i - this.index
      card.classList.toggle("card--front", offset === 0)
      card.classList.toggle("card--behind", offset > 0 && offset <= 2)
      card.hidden = offset < 0 || offset > 2
      card.style.setProperty("--stack-depth", offset)
    })

    if (this.hasProgressTarget && this.cardTargets.length > 0) {
      this.progressTarget.textContent = `${this.index + 1} / ${this.cardTargets.length}`
    }

    if (this.hasEndTarget) {
      this.endTarget.hidden = !(this.index >= this.cardTargets.length - 1 && this.cardTargets.length > 0)
    }
  }

  showEnd() {
    if (this.hasEndTarget) this.endTarget.hidden = false
  }

  onKey(event) {
    if (event.target.matches("textarea, input")) return
    if (event.key === "ArrowRight") this.next()
    if (event.key === "ArrowLeft")  this.prev()
  }

  onTouchStart(event) {
    this.touchStart = event.touches[0]?.clientX ?? null
  }

  onTouchEnd(event) {
    if (this.touchStart === null) return
    const endX = event.changedTouches[0]?.clientX ?? this.touchStart
    const delta = endX - this.touchStart
    if (Math.abs(delta) > 40) {
      delta < 0 ? this.next() : this.prev()
    }
    this.touchStart = null
  }
}
