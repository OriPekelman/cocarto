import { Controller } from '@hotwired/stimulus'

// This controller handles information concerning a single layer
// - what is its bounding box (handling adding/removing rows)
// - is it shown or collapsed

export default class extends Controller {
  static values = {
    geometryType: String,
    addFeatureText: String,
    initiallyActive: Boolean
  }

  static targets = ['geojsonField', 'newRowForm', 'row', 'hideButton', 'showButton']
  static outlets = ['map', 'layer']

  mapOutletConnected () {
    queueMicrotask(() => {
      if (this.initiallyActiveValue) {
        this.activate()
      }
      this.mapOutlet.registerLayer({ layerId: this.element.id, geometryType: this.geometryTypeValue })
    })
  }

  activate () {
    if (!this.element.classList.contains('is-active')) {
      // Note: we may want to use turbo frames for each layer and
      // use data-turbo-action="advance" to switch the url when activating a frame
      this.toggleTable()
    }
  }

  row_focused (event) {
    const rowController = event.currentTarget.rowController
    rowController.focus()
    const feature = {
      id: event.params.featureId,
      source: this.element.id,
      sourceLayer: 'layer'
    }
    this.dispatch('row_focused', { detail: { feature } })
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

  showOnMap () {
    this.hideButtonTarget.hidden = false
    this.showButtonTarget.hidden = true
    this.mapOutlet.showLayer(this.element.id)
  }

  hideOnMap () {
    this.hideButtonTarget.hidden = true
    this.showButtonTarget.hidden = false
    this.mapOutlet.hideLayer(this.element.id)
  }
}
