import { Controller } from '@hotwired/stimulus'
import MapState from 'lib/map_state'

export default class extends Controller {
  static targets = ['map', 'row', 'addButton', 'defaultLatitude', 'defaultLongitude', 'defaultZoom', 'toolbarLeft', 'toolbarRight']

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

    this.addRows(this.rowTargets)
  }

  rowTargetConnected (row) {
    // a row can be connected when the map isn’t initialized yet
    if (this.mapState) {
      this.mapState.addRow(row.rowController)
    }
  }

  rowTargetDisconnected (row) {
    this.mapState.getDraw().delete(row.id)
  }

  addRows (rows) {
    rows.forEach(row => this.mapState.addRow(row.rowController))
  }

  removeRows (rows) {
    const ids = rows.map(row => row.id)
    this.mapState.getDraw().delete(ids)
  }

  layerToggled (detail) {
    if (detail.opened) {
      this.mapState.setActiveLayer(detail)
    }

    if (detail.opened && detail.geometryType !== 'territory') {
      this.addButtonTarget.innerHTML = detail.addFeatureText
      this.addButtonTarget.hidden = false
    } else {
      this.addButtonTarget.hidden = true
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

  exportMapAsImage ({ target }) {
    target.href = this.mapState.getImage()
  }

  selectFeature (event) {
    this.mapState.setSelectedFeature(event.currentTarget.id)
  }

  center ({ params: { bounds } }) {
    this.mapState.setVisibleBounds(bounds)
  }
}
