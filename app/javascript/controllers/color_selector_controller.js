import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['icon']
  static values = {
    default: String
  }

  selected (e) {
    this.setColor(e.target.dataset.color)
  }

  setColor (color) {
    this.iconTargets.forEach(t => t.style.setProperty('color', color))
  }

  connect () {
    this.setColor(this.defaultValue)
  }
}
