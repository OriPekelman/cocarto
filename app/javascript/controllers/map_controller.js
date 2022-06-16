/* global ResizeObserver */
import { Controller } from '@hotwired/stimulus'

import consumer from 'channels/consumer'
import { newMap, newMarker } from 'lib/map_helpers'
import Trackers from 'lib/trackers'
import MapboxDraw from '@mapbox/mapbox-gl-draw'

export default class extends Controller {
  static targets = ['longitudeField', 'latitudeField', 'polygonField', 'newPolygonForm', 'newPointForm', 'map', 'point']
  static values = {
    editable: Boolean,
    layerId: String,
    sessionId: String,
    username: String,
    geometryType: String
  }

  initialize () {
    this.markers = new Map()
    this.lastMoveSent = Date.now()
    this.clickTimer = null
  }

  connect () {
    this.#initMap()
    this.#initActionCable()
  }

  pointTargetConnected (point) {
    // We are accessing to the controller of the target
    // This is not very stimmulus-ish
    // So we have a bit of a timing problem, that is solved with this promise
    // https://github.com/hotwired/stimulus/issues/201#issuecomment-435285227
    Promise.resolve().then(() => {
      const marker = newMarker(point.rowController.getLngLat())
      this.markers.set(point.id, marker)
      marker.on('dragend', () =>
        point.rowController.dragged(marker.getLngLat())
      )
      if (this.map) {
        marker.addTo(this.map)
      }
    })
  }

  pointTargetDisconnected (point) {
    const id = point.id
    const m = this.markers.get(id)
    m.remove()
    this.markers.delete(id)
  }

  polygonTargetConnected (polygon) {
    // Same hack as with pointTargetConnected
    Promise.resolve().then(() => {
      const geojson = polygon.rowController.geojson()
      const feature = {
        id: polygon.id,
        type: 'Feature',
        geometry: geojson
      }
      this.draw.add(feature)
    })
  }

  polygonTargetDisconnected (polygon) {
    this.draw.delete(polygon.id)
  }

  #initMap () {
    this.map = newMap(this.mapTarget)
    this.markers.forEach(marker => marker.addTo(this.map))

    const resizeObserver = new ResizeObserver(() => this.map.resize())
    resizeObserver.observe(this.mapTarget)
    this.trackers = new Trackers(this.map)

    if (this.editableValue) {
      if (this.geometryTypeValue === 'point') {
        this.map.on('click', e => this.#handleClick(e))
      } else if (this.geometryTypeValue === 'polygon') {
        this.#initPolygonDraw()
      } else {
        console.error('Unknown geometry type', this.geometryTypeValue)
      }

      this.map.on('mousemove', e => {
        if (Date.now() - this.lastMoveSent > 20) {
          this.channel.mouse_moved(e.lngLat)
          this.lastMoveSent = Date.now()
        }
      })
    }
  }

  #initActionCable () {
    const _this = this
    this.channel = consumer.subscriptions.create({ channel: 'SharePositionChannel', layer: this.layerIdValue }, {
      connected () {
        console.log('SharePositionChannel connected')
      },
      disconnected () {
        console.log('SharePositionChannel disconnected')
      },
      received (data) {
        if (data.sessionId !== _this.sessionIdValue) {
          _this.trackers.upsert(data)
        }
      },
      mouse_moved (lngLat) {
        return this.perform('mouse_moved', {
          lngLat,
          name: _this.usernameValue,
          sessionId: _this.sessionIdValue,
          layerId: _this.layerIdValue
        })
      }
    })
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
    this.draw = new MapboxDraw({
      displayControlsDefault: false,
      // Select which mapbox-gl-draw control buttons to add to the map.
      controls: {
        polygon: true
      },
      // Set mapbox-gl-draw to draw by default.
      // The user does not have to click the polygon control button first.
      defaultMode: 'draw_polygon'
    })
    this.map.addControl(this.draw)
    this.map.on('draw.create', ({ features }) => {
      this.polygonFieldTarget.value = JSON.stringify(features[0].geometry)
      this.newPolygonFormTarget.requestSubmit()
    })
    this.map.on('draw.update', ({ features }) => {
      const id = features[0].id
      const polygon = document.getElementById(id)
      polygon.rowController.updatePolygon(features[0].geometry)
    })
  }
}
