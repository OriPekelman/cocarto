import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['template', 'value']

  connect () {
    // We always want to be able to add a new value
    this.#addNewInput()
  }

  newValue (event) {
    // Did we modify the last input?
    if (this.valueTargets[this.valueTargets.length - 1] === event.target) {
      // Did we actually set a value ?
      if (event.target.value !== '') {
        // Then let’s add a new input for an extra value
        this.#addNewInput()
      }
    } else if (event.target.value === '') {
      // If the input is empty (and it wasn’t the last input) we remove it
      event.target.remove()
    }
  }

  #addNewInput () {
    const newInput = this.templateTarget.content.cloneNode(true)
    this.element.appendChild(newInput)
  }
}
