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
      this.#setPosition(e.clientX)
    }
  }

  mouseup () {
    this.dragging = false
  }

  #setPosition (x) {
    this.element.style.setProperty('--left-pane-width', `min(calc(100vw - var(--dragbar-width)), calc(${x}px - var(--dragbar-width) / 2))`)
    this.element.style.setProperty('--right-pane-width', `min(calc(100vw - var(--dragbar-width)), calc(100vw - ${x}px - var(--dragbar-width) / 2))`)
    this.dispatch('panel_changed', { detail: { value: this.#panelAtPosition(x) } })
  }

  toggle(toggled) {
    const currentPanel = this.#panelAtPosition(this.leftTarget.offsetWidth)
    if (currentPanel === 'both') {
      if (toggled === 'table') {
        this.#setPosition(this.element.offsetWidth)
      } else {
        this.#setPosition(0)
      }
    } else {
      this.#setPosition(this.element.offsetWidth / 2)
    }
  }

  panelValue () {
    return this.#panelAtPosition(this.leftTarget.offsetWidth)
  }

  #panelAtPosition (x) {
    const margin = 10
    if (x < margin) {
      return 'map'
    } else if (x > this.element.offsetWidth - margin) {
      return 'table'
    } else {
      return 'both'
    }
  }
}
