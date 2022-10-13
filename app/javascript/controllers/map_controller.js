/* global ResizeObserver */
import { Controller } from '@hotwired/stimulus'

import { newMap, maplibreGLFeaturesStyle, geocoderApi } from 'lib/map_helpers'
import PresenceTrackers from 'lib/presence_trackers'
import MapboxDraw from '@mapbox/mapbox-gl-draw'
import MaplibreGeocoder from '@maplibre/maplibre-gl-geocoder'
import maplibregl from 'maplibre-gl'

export default class extends Controller {
  static targets = ['geojsonField', 'newRowForm', 'row', 'map', 'addButton']
  static values = {
    layerId: String,
    sessionId: String,
    username: String,
    geometryType: String,
    color: String
  }

  initialize () {
    this.boundingBox = null
  }

  connect () {
    this.#initMap()
    this.trackers = new PresenceTrackers(this)
    this.drawMode = `draw_${this.geometryTypeValue}`
  }

  rowTargetConnected (row) {
    // a row can be connected when this.draw isn’t initialized yet
    if (this.draw) {
      this.#addRow(row)
    }
    this.#extendBounds(row)
  }

  rowTargetDisconnected (row) {
    this.draw.delete(row.id)
    this.boundingBox = null

    this.rowTargets.forEach(otherRow => this.#extendBounds(otherRow))
  }

  centerToContent () {
    if (this.geometryTypeValue === 'point' && this.rowTargets.length === 1) {
      this.map.setCenter(this.boundingBox.getCenter())
    } else {
      this.map.fitBounds(this.boundingBox, { padding: 20 })
    }
  }

  centerToRow (event) {
    const row = event.target.closest('tr')

    const llb = row.rowController.bounds()

    if (this.geometryTypeValue === 'point') {
      this.map.setCenter(llb.getCenter())
    } else {
      this.map.fitBounds(llb, { padding: 20 })
    }
  }

  toggleMode () {
    const newMode = this.draw.getMode() === this.drawMode ? 'simple_select' : this.drawMode
    this.draw.changeMode(newMode)
    this.#modeChange(newMode)
  }

  // Private functions
  #initMap () {
    this.map = newMap(this.mapTarget)

    this.#initRowDraw()
    this.rowTargets.forEach(row => this.#addRow(row))

    const resizeObserver = new ResizeObserver(() => this.map.resize())
    resizeObserver.observe(this.mapTarget)

    this.map.on('mousemove', e => this.trackers.mousemove(e))

    const geolocate = new maplibregl.GeolocateControl({
      positionOptions: {
        enableHighAccuracy: true
      },
      trackUserLocation: true
    })

    this.map.addControl(geolocate)

    this.map.addControl(
      new MaplibreGeocoder(geocoderApi, {
        maplibregl
      })
    )
  }

  #initRowDraw () {
    const rwOptions = {
      displayControlsDefault: false,
      styles: maplibreGLFeaturesStyle(this.colorValue),
      userProperties: true
    }

    const roOptions = {
      displayControlsDefault: false,
      styles: maplibreGLFeaturesStyle(this.colorValue),
      userProperties: true
    }

    const editable = this.geometryTypeValue !== 'territory'
    this.draw = new MapboxDraw(editable ? rwOptions : roOptions)
    this.map.addControl(this.draw)

    this.map.on('draw.create', ({ features }) => {
      this.geojsonFieldTarget.value = JSON.stringify(features[0].geometry)
      this.newRowFormTarget.requestSubmit()
      // When we submit the drawn row, we get one back from the server through turbo
      // So we remove the one we’ve just drawn
      this.draw.delete(features[0].id)
    })
    this.map.on('draw.update', ({ features }) => {
      const id = features[0].id
      const row = document.getElementById(id)
      row.rowController.update(features[0].geometry)
    })
    this.map.on('draw.modechange', ({ mode }) => this.#modeChange(mode))
  }

  #addRow (row) {
    const geometry = row.rowController.geojson()
    const feature = {
      id: row.id,
      type: 'Feature',
      properties: row.rowController.propertiesValue,
      geometry
    }
    this.draw.add(feature)
  }

  #extendBounds (row) {
    const llb = row.rowController.bounds()

    if (this.boundingBox === null) {
      this.boundingBox = llb
    } else {
      this.boundingBox = this.boundingBox.extend(llb)
    }
  }

  #modeChange (mode) {
    if (mode === this.drawMode) {
      this.addButtonTarget.classList.add('active')
    } else {
      this.addButtonTarget.classList.remove('active')
    }
  }
}
