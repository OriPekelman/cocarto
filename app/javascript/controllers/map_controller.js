import { Controller } from '@hotwired/stimulus'
import MapState from 'lib/map_state'
import * as modes from 'lib/modes'

export default class extends Controller {
  static targets = ['map', 'row', 'addButton', 'defaultLatitude', 'defaultLongitude', 'defaultZoom', 'toolbarLeft', 'toolbarRight', 'layerUpdate']

  static values = {
    mapId: String,
    styleUrl: String,
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
      rightToolbar: this.toolbarRightTarget,
      style: this.styleUrlValue
    })
  }

  showLayer (layerId) {
    this.mapState.showLayer(layerId)
  }

  hideLayer (layerId) {
    this.mapState.hideLayer(layerId)
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
    console.log(modes)
    if (this.mapState.getMode() === modes.DEFAULT) {
      this.mapState.setMode(modes.ADD_FEATURE)
    } else {
      this.mapState.setMode(modes.DEFAULT)
    }
  }

  exportMapAsImage ({ target }) {
    target.href = this.mapState.getImage()
  }

  selectFeature ({ detail }) {
    this.mapState.setSelectedFeature(detail.feature)
  }

  center ({ params: { bounds } }) {
    this.mapState.setVisibleBounds(bounds)
  }

  layerUpdateTargetConnected (update) {
    this.mapState.refresh(update.dataset.layerId)
  }

  registerLayer (layerId) {
    this.mapState.registerLayer(layerId)
  }
}
