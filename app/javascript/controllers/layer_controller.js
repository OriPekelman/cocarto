import { Controller } from '@hotwired/stimulus'

// This controller handles informations concerning a single layer
// - what is its bounding box (handling adding/removing rows)
// - is it shown or collapsed

export default class extends Controller {
  static values = {
    geometryType: String,
    addFeatureText: String
  }

  static targets = ['geojsonField', 'newRowForm', 'row']
  static outlets = ['layer']

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
    // Close the other active layer if it exists
    if (this.hasLayerOutlet && this.layerOutletElement !== this.element) {
      this.layerOutletElement.classList.remove('is-active')
    }

    const opened = this.element.classList.toggle('is-active')
    const detail = {
      layerController: this,
      opened,
      geometryType: this.geometryTypeValue,
      addFeatureText: this.addFeatureTextValue
    }
    this.dispatch('toggled', { detail })
  }

  createRow (geometry) {
    this.geojsonFieldTarget.value = JSON.stringify(geometry)
    this.newRowFormTarget.requestSubmit()
  }

  #extendBounds (row) {
    const llb = row.rowController.bounds()
    this.boundingBox = llb.extend(this.boundingBox)
  }
}
