import { Controller } from '@hotwired/stimulus'
import { useClickOutside } from 'stimulus-use'
import { computePosition, offset, autoUpdate, flip } from '@floating-ui/dom'

export default class extends Controller {
  static targets = ['trigger', 'content']
  static values = {
    placement: { type: String, default: 'bottom-start' },
    offset: Number,
    loaded: Boolean
  }

  connect () {
    this.element.dataset[`${this.identifier}Controller`] = 'connected'
    autoUpdate(this.triggerTarget, this.contentTarget, () => { this.#adjustPosition() })
    useClickOutside(this)
  }

  toggle (event) {
    if (this.contentTarget.contains(event.target)) {
      return
    }

    if (this.element.classList.contains('is-active')) {
      this.deactivate()
    } else {
      this.activate()
    }
  }

  activate () {
    this.#adjustPosition()
    this.element.classList.add('is-active')
  }

  deactivate () {
    this.element.classList.remove('is-active')
  }

  clickOutside (event) {
    this.deactivate()
  }

  #adjustPosition () {
    computePosition(this.triggerTarget, this.contentTarget, {
      placement: this.placementValue,
      middleware: [offset(this.offsetValue), flip()]
    }).then(({ x, y }) => {
      Object.assign(this.contentTarget.style, {
        left: `${x}px`,
        top: `${y}px`,
        'min-width': `${this.triggerTarget.offsetWidth}px`
      })
    })
  }
}
