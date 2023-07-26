import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['button', 'toggle']
  static outlets = ['dragbar']

  dragbarOutletConnected (outlet, outletElement) {
    outletElement.addEventListener('dragbar:panel_changed', (e) => this.#panelChanged(e.detail.value))
    this.#panelChanged(outlet.panelValue())
  }

  toggle ({ params: { value } }) {
    this.dragbarOutlet.toggle(value)
  }

  #panelChanged (value) {
    for (const button of this.buttonTargets) {
      button.classList.remove('segment--hidden')
      button.classList.remove('segment--focus')
    }
    if (value === 'both') {
      return
    }
    for (const button of this.buttonTargets) {
      if (value === button.dataset.segmentedBarValueParam) {
        button.classList.add('segment--focus')
      } else {
        button.classList.add('segment--hidden')
      }
    }
  }
}
