import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['left', 'right', 'dragbar']

  connect () {
    this.dragging = false
    this.dragbarTarget.addEventListener('mousedown', e => this.mousedown(e))
    window.addEventListener('mousemove', e => this.mousemove(e))
    document.addEventListener('mouseup', () => this.mouseup())
  }

  mousedown (event) {
    event.preventDefault()
    this.dragging = true
  }

  mousemove (e) {
    if (this.dragging) {
      this.element.style.setProperty('--left-pane-width', `max(7em, calc(${e.clientX}px - var(--dragbar-width) / 2))`)
      this.element.style.setProperty('--right-pane-width', `max(7em, calc(100vw - ${e.clientX}px - var(--dragbar-width) / 2))`)
    }
  }

  mouseup () {
    this.dragging = false
  }
}
