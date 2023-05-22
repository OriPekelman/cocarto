import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['icon', 'territoryCategories']

  connect () {
    const defaultValue = this.element.elements['layer[color]'].value
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
