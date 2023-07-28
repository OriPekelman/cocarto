import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['icon', 'colorInput', 'territoryCategories']

  connect () {
    const defaultValue = this.colorInputTargets.find(e => e.checked).value
    this.setColor(defaultValue)
  }

  colorSelected ({ params }) {
    this.setColor(params.color)
  }

  setColor (color) {
    this.iconTargets.forEach(t => t.style.setProperty('color', color))
  }

  typeSelected ({ params }) {
    this.territoryCategoriesTargets.forEach(t => { t.hidden = (params.type !== 'territory') })
  }
}
