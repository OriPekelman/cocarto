/* global ResizeObserver */
import { Controller } from '@hotwired/stimulus'

import { newMap, newMarker } from 'lib/map_helpers'
import Trackers from 'lib/trackers'
import MapboxDraw from '@mapbox/mapbox-gl-draw'

export default class extends Controller {
  static targets = ['longitudeField', 'latitudeField', 'polygonField', 'newPolygonForm', 'newPointForm', 'map', 'point', 'polygon']
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
    this.trackers = new Trackers(this)
  }

  pointTargetConnected (point) {
    const marker = newMarker(point.rowController.getLngLat())
    this.markers.set(point.id, marker)
    marker.on('dragend', () =>
      point.rowController.dragged(marker.getLngLat())
    )
    if (this.map) {
      marker.addTo(this.map)
    }
  }

  pointTargetDisconnected (point) {
    const id = point.id
    const m = this.markers.get(id)
    m.remove()
    this.markers.delete(id)
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

  #initMap () {
    this.map = newMap(this.mapTarget)
    if (this.geometryTypeValue === 'point') {
      this.markers.forEach(marker => marker.addTo(this.map))
    } else if (this.geometryTypeValue === 'polygon') {
      this.#initPolygonDraw()
      this.polygonTargets.forEach(polygon => this.#addPolygon(polygon))
    }

    const resizeObserver = new ResizeObserver(() => this.map.resize())
    resizeObserver.observe(this.mapTarget)

    if (this.editableValue) {
      if (this.geometryTypeValue === 'point') {
        this.map.on('click', e => this.#handleClick(e))
      }

      this.map.on('mousemove', e => this.trackers.mousemove(e))
    }
  }

  #handleClick (event) {
    // It is the first click, a second might happen if the user double-clicks
    if (event.originalEvent.detail === 1) {
      // We put the submit in a timeout so it can be canceled if it was a doubleclick
      this.clickTimer = setTimeout(() => {
        this.longitudeFieldTarget.value = event.lngLat.lng
        this.latitudeFieldTarget.value = event.lngLat.lat
        this.newPointFormTarget.requestSubmit()
      }, 500) // Is there a way to accually know what the double-click delay is?
    } else if (this.clickTimer !== null) {
      // Oh! it was a double click. ABORT!
      // We didn’t want to create a new point
      clearTimeout(this.clickTimer)
      this.clickTimer = null
    }
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
