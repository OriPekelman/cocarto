import { Controller } from '@hotwired/stimulus'

// This controller handles informations concerning a single layer
// - what is its bounding box (handling adding/removing rows)
// - is it shown or collapsed

export default class extends Controller {
  static targets = ['row']

  initialize () {
    this.boundingBox = null
  }

  rowTargetConnected (row) {
    this.#extendBounds(row)
  }

  rowTargetDisconnected () {
    this.boundingBox = null
    this.rowTargets.forEach(otherRow => this.#extendBounds(otherRow))
  }

  center () {
    if (this.boundingBox !== null) {
      this.dispatch('center', { detail: { boundingBox: this.boundingBox } })
    }
  }

  toggleTable () {
    if (this.element.classList.toggle('is-active')) {
      this.dispatch('opened', { details: this.element })
    }
  }

  #extendBounds (row) {
    const llb = row.rowController.bounds()
    this.boundingBox = llb.extend(this.boundingBox)
  }
}
