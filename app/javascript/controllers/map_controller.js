import { Controller } from '@hotwired/stimulus'
import MapState from 'lib/map_state'

export default class extends Controller {
  static targets = ['map', 'addButton', 'defaultLatitude', 'defaultLongitude', 'defaultZoom', 'toolbarLeft', 'toolbarRight']
  static outlets = ['row']
  static values = {
    mapId: String,
    defaultLatitude: Number,
    defaultLongitude: Number,
    defaultZoom: Number
  }

  connect () {
    this.mapState = new MapState({
      target: this.mapTarget,
      mapId: this.mapIdValue,
      lng: this.defaultLongitudeValue,
      lat: this.defaultLatitudeValue,
      zoom: this.defaultZoomValue,
      leftToolbar: this.toolbarLeftTarget,
      rightToolbar: this.toolbarRightTarget
    })

    this.rowOutlets.forEach(row => this.mapState.addRow(row))
  }

  rowOutletConnected (controller, element) {
    // a row can be connected when  isn’t initialized yet
    if (this.mapState) {
      this.mapState.addRow(controller)
    }
    setTimeout(() => element.classList.remove('highlight-transition'), 1000)
    setTimeout(() => element.classList.remove('bg-transition'), 3000)
  }

  rowOutletDisconnected (row) {
    this.mapState.getDraw().delete(row.id)
  }

  layerToggled ({ detail }) {
    if (detail.opened) {
      this.mapState.setActiveLayer(detail)
    }

    if (detail.opened && detail.geometryType !== 'territory') {
      this.addButtonTarget.innerHTML = detail.addFeatureText
      this.addButtonTarget.classList.remove('is-hidden')
    } else {
      this.addButtonTarget.classList.add('is-hidden')
    }
  }

  setDefaultCenterZoom () {
    const { lng, lat, zoom } = this.mapState.getCurrentView()
    this.defaultLongitudeTarget.value = lng
    this.defaultLatitudeTarget.value = lat
    this.defaultZoomTarget.value = zoom
  }

  toggleMode () {
    const newMode = this.mapState.getDraw().getMode() === this.mapState.getDrawMode() ? 'simple_select' : this.mapState.getDrawMode()
    this.mapState.getDraw().changeMode(newMode)
  }

  highlightFeatures (event) {
    this.mapState.setSelectedFeature(event.target.closest('tr').id)
  }

  exportMapAsImage ({ target }) {
    target.href = this.mapState.getImage()
  }
}
