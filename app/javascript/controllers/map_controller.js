import maplibre from 'maplibre-gl'
import { Controller } from '@hotwired/stimulus'

import consumer from "channels/consumer"
import { new_map, newMarker } from "lib/map_helpers"
import Trackers from 'lib/trackers'

export default class extends Controller {
  static targets = ['longitudeField', 'latitudeField', 'newPointForm', 'map', 'point']
  static values = {
    editable: Boolean,
    layerId: String,
    sessionId: String,
    username: String,
  }

  initialize () {
    this.markers = new Map()
    this.lastMoveSent = Date.now()
  }

  connect () {
    this.#initMap()
    this.#initActionCable()
  }

  pointTargetConnected (point) {
    const marker = newMarker(point.rowController.getLngLat())
    this.markers.set(point.id, marker)
    marker.on('dragend', () => point.rowController.dragged(marker.getLngLat()))
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

  #initMap () {
    this.map = new_map(this.mapTarget)
    this.markers.forEach(marker => marker.addTo(this.map))

    const resizeObserver = new ResizeObserver (( ) => this.map.resize())
    resizeObserver.observe(this.mapTarget)
    this.trackers = new Trackers(this.map)

    if (this.editableValue){
      this.map.on('click', e => {
        this.longitudeFieldTarget.value = e.lngLat.lng
        this.latitudeFieldTarget.value = e.lngLat.lat
        this.newPointFormTarget.requestSubmit()
      })

      this.map.on('mousemove', e => {
        if (Date.now() - this.lastMoveSent > 20) {
          this.channel.mouse_moved(e.lngLat)
          this.lastMoveSent = Date.now()
        }
      })
    }
  }

  #initActionCable() {
    const _this = this
    this.channel = consumer.subscriptions.create({channel: 'SharePositionChannel', layer: this.layerIdValue}, {
      connected() {
        console.log('SharePositionChannel connected')
      },
      disconnected() {
        console.log('SharePositionChannel disconnected')
      },
      received(data) {
        if(data.sessionId !== _this.sessionIdValue) {
          _this.trackers.upsert(data)
        }
      },
      mouse_moved(lngLat) {
        return this.perform('mouse_moved', {
          lngLat,
          name: _this.usernameValue,
          sessionId: _this.sessionIdValue,
          layerId: _this.layerIdValue
        });
      },
    });
  }

}
