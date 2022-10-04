/* global ResizeObserver */
import { Controller } from '@hotwired/stimulus'

import { newMap, maplibreGLFeaturesStyle } from 'lib/map_helpers'
import PresenceTrackers from 'lib/presence_trackers'
import MapboxDraw from '@mapbox/mapbox-gl-draw'

export default class extends Controller {
  static targets = ['geojsonField', 'newRowForm', 'row', 'map']
  static values = {
    layerId: String,
    sessionId: String,
    username: String,
    geometryType: String,
    color: String
  }

  initialize () {
    this.markers = new Map()
    this.clickTimer = null
    this.boundingBox = null
  }

  connect () {
    this.#initMap()
    this.trackers = new PresenceTrackers(this)
  }

  #extendBounds (row) {
    const llb = row.rowController.bounds()

    if (this.boundingBox === null) {
      this.boundingBox = llb
    } else {
      this.boundingBox = this.boundingBox.extend(llb)
    }
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

  #initMap () {
    this.map = newMap(this.mapTarget)

    this.#initRowDraw()
    this.rowTargets.forEach(row => this.#addRow(row))

    const resizeObserver = new ResizeObserver(() => this.map.resize())
    resizeObserver.observe(this.mapTarget)

    this.map.on('mousemove', e => this.trackers.mousemove(e))
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

  changeMode () {
    this.draw.changeMode(`draw_${this.geometryTypeValue}`)
  }

  #initRowDraw () {
    const rwOptions = {
      displayControlsDefault: false,
      // Set mapbox-gl-draw to draw by default.
      // The user does not have to click the polygon control button first.
      defaultMode: `draw_${this.geometryTypeValue}`,
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
}
