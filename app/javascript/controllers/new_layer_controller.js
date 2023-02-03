import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['icon', 'territoryCategories']
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

  typeSelected ({ params }) {
    this.territoryCategoriesTargets.forEach(t => { t.hidden = (params.type !== 'territory') })
  }
}
