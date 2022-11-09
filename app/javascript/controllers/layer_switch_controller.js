import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  toggle () {
    if (this.element.classList.contains('is-active')) {
      this.deactivate()
    } else {
      this.activate()
    }
  }

  activate () {
    for (const layer of document.querySelectorAll('.layer-table__container.is-active')) {
      layer.classList.remove('is-active')
    }
    this.element.classList.add('is-active')
  }

  deactivate () {
    this.element.classList.remove('is-active')
  }
}
