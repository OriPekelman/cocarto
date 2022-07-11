/* global ResizeObserver */
import { Controller } from '@hotwired/stimulus'

import { newMap, maplibreGLFeaturesStyle } from 'lib/map_helpers'
import PresenceTrackers from 'lib/presence_trackers'
import MapboxDraw from '@mapbox/mapbox-gl-draw'

export default class extends Controller {
  static targets = ['geojsonField', 'newRowForm', 'row', 'map']
  static values = {
    editable: Boolean,
    layerId: String,
    sessionId: String,
    username: String,
    geometryType: String,
    color: String
  }

  initialize () {
    this.markers = new Map()
    this.clickTimer = null
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
  }

  rowTargetDisconnected (row) {
    this.draw.delete(row.id)
  }

  #initMap () {
    this.map = newMap(this.mapTarget)

    if (this.geometryTypeValue !== 'territory') {
      this.#initRowDraw()
      this.rowTargets.forEach(row => this.#addRow(row))
    }

    const resizeObserver = new ResizeObserver(() => this.map.resize())
    resizeObserver.observe(this.mapTarget)

    if (this.editableValue) {
      this.map.on('mousemove', e => this.trackers.mousemove(e))
    }
  }

  #initRowDraw () {
    const rwOptions = {
      displayControlsDefault: false,
      controls: {
        [this.geometryTypeValue]: true
      },
      // Set mapbox-gl-draw to draw by default.
      // The user does not have to click the polygon control button first.
      defaultMode: `draw_${this.geometryTypeValue}`,
      styles: maplibreGLFeaturesStyle(this.colorValue)
    }

    const roOptions = {
      displayControlsDefault: false,
      styles: maplibreGLFeaturesStyle(this.colorValue)
    }

    this.draw = new MapboxDraw(this.editableValue ? rwOptions : roOptions)
    this.map.addControl(this.draw)

    if (this.editableValue) {
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
  }

  #addRow (row) {
    const geometry = row.rowController.geojson()
    const feature = {
      id: row.id,
      type: 'Feature',
      geometry
    }
    this.draw.add(feature)
  }
}
