import { Controller } from '@hotwired/stimulus'

// This controller handles informations concerning a single layer
// - what is its bounding box (handling adding/removing rows)
// - is it shown or collapsed

export default class extends Controller {
  static values = {
    geometryType: String,
    addFeatureText: String
  }

  static targets = ['geojsonField', 'newRowForm', 'row', 'hideButton', 'showButton']
  static outlets = ['map', 'layer']

  connect () {
    // If the url contains ?open=id we open this layer
    // We use the query string and not an achor because of a turbo bug with redirections
    // See https://github.com/hotwired/turbo/issues/211
    const id = new URL(document.location).searchParams.get('open')
    if (id === this.element.id && !this.element.classList.contains('is-active')) {
      this.toggleTable()
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

  showOnMap () {
    this.hideButtonTarget.hidden = false
    this.showButtonTarget.hidden = true
    this.mapOutlet.addRows(this.rowTargets)
  }

  hideOnMap () {
    this.hideButtonTarget.hidden = true
    this.showButtonTarget.hidden = false
    this.mapOutlet.removeRows(this.rowTargets)
  }
}
