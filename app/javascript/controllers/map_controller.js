/* global ResizeObserver */
import { Controller } from '@hotwired/stimulus'

import { newMap } from 'lib/map_helpers'
import PresenceTrackers from 'lib/presence_trackers'
import MapboxDraw from '@mapbox/mapbox-gl-draw'

export default class extends Controller {
  static targets = ['pointField', 'lineStringField', 'polygonField', 'newPolygonForm', 'newLineStringForm', 'newPointForm', 'map', 'point', 'lineString', 'polygon']
  static values = {
    editable: Boolean,
    layerId: String,
    sessionId: String,
    username: String,
    geometryType: String
  }

  initialize () {
    this.markers = new Map()
    this.clickTimer = null
  }

  connect () {
    this.#initMap()
    this.trackers = new PresenceTrackers(this)
  }

  pointTargetConnected (point) {
    // a point can be connected when this.draw isn’t initialized yet
    if (this.draw) {
      this.#addPoint(point)
    }
  }

  pointTargetDisconnected (point) {
    this.draw.delete(point.id)
  }

  polygonTargetConnected (polygon) {
    // a polygon can be connected when this.draw isn’t initialized yet
    if (this.draw) {
      this.#addPolygon(polygon)
    }
  }

  polygonTargetDisconnected (polygon) {
    this.draw.delete(polygon.id)
  }

  lineStringTargetConnected (lineString) {
    // a lineString can be connected when this.draw isn’t initialized yet
    if (this.draw) {
      this.#addLineString(lineString)
    }
  }

  lineStringTargetDisconnected (lineString) {
    this.draw.delete(lineString.id)
  }

  #initMap () {
    this.map = newMap(this.mapTarget)
    if (this.geometryTypeValue === 'point') {
      this.#initPointDraw()
      this.pointTargets.forEach(point => this.#addPoint(point))
    } else if (this.geometryTypeValue === 'line_string') {
      this.#initLineStringDraw()
      this.lineStringTargets.forEach(lineString => this.#addLineString(lineString))
    } else if (this.geometryTypeValue === 'polygon') {
      this.#initPolygonDraw()
      this.polygonTargets.forEach(polygon => this.#addPolygon(polygon))
    }

    const resizeObserver = new ResizeObserver(() => this.map.resize())
    resizeObserver.observe(this.mapTarget)

    if (this.editableValue) {
      this.map.on('mousemove', e => this.trackers.mousemove(e))
    }
  }

  #initPointDraw () {
    const rwOptions = {
      displayControlsDefault: false,
      // Select which mapbox-gl-draw control buttons to add to the map.
      controls: {
        point: true
      },
      // Set mapbox-gl-draw to draw by default.
      // The user does not have to click the point control button first.
      defaultMode: 'draw_point'
    }

    const roOptions = {
      displayControlsDefault: false
    }

    this.draw = new MapboxDraw(this.editableValue ? rwOptions : roOptions)
    this.map.addControl(this.draw)

    if (this.editableValue) {
      this.map.on('draw.create', ({ features }) => {
        this.pointFieldTarget.value = JSON.stringify(features[0].geometry)
        this.newPointFormTarget.requestSubmit()
        // When we submit the drawn line_string, we get one back from the server through turbo
        // So we remove the one we’ve just drawn
        this.draw.delete(features[0].id)
      })
      this.map.on('draw.update', ({ features }) => {
        const id = features[0].id
        const point = document.getElementById(id)
        point.pointController.update(features[0].geometry)
      })
    }
  }

  #addPoint (point) {
    const geometry = point.pointController.geojson()
    const feature = {
      id: point.id,
      type: 'Feature',
      geometry
    }
    this.draw.add(feature)
  }

  #initLineStringDraw () {
    const rwOptions = {
      displayControlsDefault: false,
      // Select which mapbox-gl-draw control buttons to add to the map.
      controls: {
        line_string: true
      },
      // Set mapbox-gl-draw to draw by default.
      // The user does not have to click the polygon control button first.
      defaultMode: 'draw_line_string'
    }

    const roOptions = {
      displayControlsDefault: false
    }

    this.draw = new MapboxDraw(this.editableValue ? rwOptions : roOptions)
    this.map.addControl(this.draw)

    if (this.editableValue) {
      this.map.on('draw.create', ({ features }) => {
        this.lineStringFieldTarget.value = JSON.stringify(features[0].geometry)
        this.newLineStringFormTarget.requestSubmit()
        // When we submit the drawn line_string, we get one back from the server through turbo
        // So we remove the one we’ve just drawn
        this.draw.delete(features[0].id)
      })
      this.map.on('draw.update', ({ features }) => {
        const id = features[0].id
        const lineString = document.getElementById(id)
        lineString.lineStringController.update(features[0].geometry)
      })
    }
  }

  #addLineString (lineString) {
    const geometry = lineString.lineStringController.geojson()
    const feature = {
      id: lineString.id,
      type: 'Feature',
      geometry
    }
    this.draw.add(feature)
  }

  #initPolygonDraw () {
    const rwOptions = {
      displayControlsDefault: false,
      // Select which mapbox-gl-draw control buttons to add to the map.
      controls: {
        polygon: true
      },
      // Set mapbox-gl-draw to draw by default.
      // The user does not have to click the polygon control button first.
      defaultMode: 'draw_polygon'
    }

    const roOptions = {
      displayControlsDefault: false
    }

    this.draw = new MapboxDraw(this.editableValue ? rwOptions : roOptions)
    this.map.addControl(this.draw)

    if (this.editableValue) {
      this.map.on('draw.create', ({ features }) => {
        this.polygonFieldTarget.value = JSON.stringify(features[0].geometry)
        this.newPolygonFormTarget.requestSubmit()
        // When we submit the drawn polygon, we get one back from the server through turbo
        // So we remove the one we’ve just drawn
        this.draw.delete(features[0].id)
      })
      this.map.on('draw.update', ({ features }) => {
        const id = features[0].id
        const polygon = document.getElementById(id)
        polygon.polygonController.update(features[0].geometry)
      })
    }
  }

  #addPolygon (polygon) {
    const geometry = polygon.polygonController.geojson()
    const feature = {
      id: polygon.id,
      type: 'Feature',
      geometry
    }
    this.draw.add(feature)
  }
}
