/* global ResizeObserver */
import { Controller } from '@hotwired/stimulus'

import { newMap, drawStyles, geocoderApi, newGeolocateControl } from 'lib/map_helpers'
import PresenceTrackers from 'lib/presence_trackers'
import MapboxDraw from '@mapbox/mapbox-gl-draw'
import MaplibreGeocoder from '@maplibre/maplibre-gl-geocoder'
import maplibregl from 'maplibre-gl'

export default class extends Controller {
  static targets = ['geojsonField', 'newRowForm', 'row', 'map', 'addButton', 'defaultLatitude', 'defaultLongitude', 'defaultZoom', 'toolbarLeft', 'toolbarRight']
  static values = {
    geometryType: String,
    defaultLatitude: Number,
    defaultLongitude: Number,
    defaultZoom: Number
  }

  connect () {
    this.#initMap()
    this.trackers = new PresenceTrackers(this)
  }

  rowTargetConnected (row) {
    // a row can be connected when this.draw isn’t initialized yet
    if (this.draw) {
      this.#addRow(row)
    }
    setTimeout(() => row.classList.remove('highlight-transition'), 1000)
    setTimeout(() => row.classList.remove('bg-transition'), 3000)
  }

  rowTargetDisconnected (row) {
    this.draw.delete(row.id)
  }

  layerToggle ({ params }) {
    if (this.layerId !== params.layerId) {
      this.layerId = params.layerId
      this.drawMode = `draw_${params.geometryType}`
      this.newRowForm = this.newRowFormTargets.find(form => form.dataset.layerId === this.layerId)
      this.geojsonField = this.geojsonFieldTargets.find(field => field.dataset.layerId === this.layerId)
      if (params.geometryType !== 'territory') {
        this.addButtonTarget.innerHTML = params.addFeatureText
        this.addButtonTarget.classList.remove('is-hidden')
      } else {
        this.addButtonTarget.classList.add('is-hidden')
      }
    } else { // We collapsed the current layer
      this.layerId = null
      this.addButtonTarget.classList.add('is-hidden')
    }
  }

  centerToContent ({ detail }) {
    this.map.fitBounds(detail.boundingBox, { padding: 20, maxZoom: 15 })
  }

  centerToRow ({ target }) {
    const row = target.closest('tr')
    const llb = row.rowController.bounds()
    this.map.fitBounds(llb, { padding: 20, maxZoom: 15 })
  }

  setDefaultCenterZoom () {
    const { lng, lat } = this.map.getCenter()
    const zoom = this.map.getZoom()
    this.defaultLongitudeTarget.value = lng
    this.defaultLatitudeTarget.value = lat
    this.defaultZoomTarget.value = zoom
  }

  toggleMode () {
    const newMode = this.draw.getMode() === this.drawMode ? 'simple_select' : this.drawMode
    this.draw.changeMode(newMode)
    this.#modeChange(newMode)
  }

  highlightFeatures (event) {
    const rowId = event.target.closest('tr').id
    const opt = {
      featureIds: [rowId]
    }

    this.draw.changeMode('simple_select', opt)
  }

  exportMapAsImage ({ target }) {
    target.href = this.map.getCanvas().toDataURL()
  }

  // Private functions
  #selectionChange ({ features }) {
    const highlightedRows = document.querySelectorAll('tr.highlight')
    highlightedRows.forEach(row => row.classList.remove('highlight'))

    features.forEach(feature => {
      const row = document.getElementById(feature.id)
      row.classList.add('highlight')
    })
  }

  #initMap () {
    this.map = newMap(this.mapTarget, [this.defaultLongitudeValue, this.defaultLatitudeValue], this.defaultZoomValue)

    this.#initRowDraw()
    this.rowTargets.forEach(row => this.#addRow(row))

    const resizeObserver = new ResizeObserver(() => this.map.resize())
    resizeObserver.observe(this.mapTarget)

    this.map.on('mousemove', e => this.trackers.mousemove(e))
    this.map.on('draw.selectionchange', e => this.#selectionChange(e))

    this.#addControls()
  }

  #addControls () {
    const geolocate = newGeolocateControl()
    this.toolbarRightTarget.appendChild(geolocate.onAdd(this.map))

    const navigation = new maplibregl.NavigationControl({ showCompass: false })
    this.toolbarRightTarget.appendChild(navigation.onAdd(this.map))

    const geocoder = new MaplibreGeocoder(geocoderApi, { maplibregl })
    this.toolbarLeftTarget.appendChild(geocoder.onAdd(this.map))
  }

  #initRowDraw () {
    this.draw = new MapboxDraw({
      displayControlsDefault: false,
      styles: drawStyles,
      userProperties: true
    })
    this.map.addControl(this.draw)

    this.map.on('draw.create', ({ features }) => this.#onDrawCreate(features))
    this.map.on('draw.update', ({ features }) => this.#onDrawUpdate(features))
    this.map.on('draw.modechange', ({ mode }) => this.#modeChange(mode))
  }

  #addRow (row) {
    const feature = {
      id: row.id,
      type: 'Feature',
      properties: row.rowController.propertiesValue,
      geometry: row.rowController.geojson()
    }
    this.draw.add(feature)
  }

  #modeChange (mode) {
    if (mode === this.drawMode) {
      this.addButtonTarget.classList.add('active')
    } else {
      this.addButtonTarget.classList.remove('active')
    }
  }

  #onDrawCreate (features) {
    this.geojsonField.value = JSON.stringify(features[0].geometry)
    this.newRowForm.requestSubmit()
    // When we submit the drawn row, we get one back from the server through turbo
    // So we remove the one we’ve just drawn
    this.draw.delete(features[0].id)
  }

  #onDrawUpdate (features) {
    const id = features[0].id
    const row = document.getElementById(id)
    row.rowController.update(features[0].geometry)
  }
}
