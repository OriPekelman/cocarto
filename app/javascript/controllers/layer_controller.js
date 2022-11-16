import { Controller } from '@hotwired/stimulus'

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

  #extendBounds (row) {
    const llb = row.rowController.bounds()
    this.boundingBox = llb.extend(this.boundingBox)
  }
}
