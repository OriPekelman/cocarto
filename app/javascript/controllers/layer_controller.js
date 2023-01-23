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
  static outlets = ['map', 'layer']

  center () {
    const boundingBox = this.rowTargets
      .map(row => row.rowController.bounds())
      .reduce((bbox, bounds) => bbox.extend(bounds))
    if (boundingBox !== null) {
      this.mapOutlet.mapState.setVisibleBounds(boundingBox)
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
    this.mapOutlet.layerToggled(detail)
  }

  createRow (geometry) {
    this.geojsonFieldTarget.value = JSON.stringify(geometry)
    this.newRowFormTarget.requestSubmit()
  }
}
