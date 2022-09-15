import { Controller } from '@hotwired/stimulus'
import { computePosition, offset, autoUpdate, flip } from '@floating-ui/dom'

export default class extends Controller {
  static targets = ['trigger', 'content']
  static values = {
    placement: { type: String, default: 'bottom-start' },
    offset: Number,
    loaded: Boolean,
    exclusive: { type: Boolean, default: true }
  }

  connect () {
    const trigger = this.triggerTarget
    const content = this.contentTarget

    autoUpdate(trigger, content, () => {
      computePosition(trigger, content, {
        placement: this.placementValue,
        middleware: [offset(this.offsetNumber), flip()]
      }).then(({ x, y }) => {
        Object.assign(content.style, {
          left: `${x}px`,
          top: `${y}px`
        })
      })
    })
    this.loadedValue = true
  }

  toggle () {
    if (this.element.classList.contains('is-active')) {
      this.deactivate()
    } else {
      this.activate()
    }
  }

  activate () {
    if (this.exclusiveValue) {
      this.#deactivateAllDropdowns()
    }
    this.element.classList.add('is-active')
  }

  deactivate () {
    this.element.classList.remove('is-active')
  }

  #deactivateAllDropdowns () {
    for (const dropdown of document.querySelectorAll('.dropdown.is-active')) {
      dropdown.classList.remove('is-active')
    }
  }
}
