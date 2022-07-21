import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['icon']
  static values = {
    defaultColor: String
  }

  connect () {
    this.setColor(this.defaultColorValue)
  }

  colorSelected ({ params }) {
    this.setColor(params.color)
  }

  setColor (color) {
    this.iconTargets.forEach(t => t.style.setProperty('color', color))
  }

  connect () {
    this.setColor(this.defaultColorValue)
  }
}
