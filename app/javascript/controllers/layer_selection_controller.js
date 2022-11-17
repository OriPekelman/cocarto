import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['layer']

  opened ({ target }) {
    this.layerTargets
      .filter(layer => layer !== target)
      .forEach(layer => layer.classList.remove('is-active'))
  }
}
