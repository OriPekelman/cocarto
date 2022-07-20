import { Controller } from '@hotwired/stimulus'
import { computePosition, offset, autoUpdate, flip } from '@floating-ui/dom'

export default class extends Controller {
  static targets = ['trigger', 'content']
  static values = {
    placement: { type: String, default: 'bottom-start' },
    offset: Number,
    loaded: Boolean
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
    this.element.classList.toggle('is-active')
  }

  activate () {
    this.element.classList.add('is-active')
  }

  desactivate () {
    this.element.classList.remove('is-active')
  }
}
