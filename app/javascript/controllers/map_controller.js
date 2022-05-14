import maplibre from 'maplibre-gl'
import { Controller } from '@hotwired/stimulus'

import consumer from "channels/consumer"
import { new_map } from "lib/map_helpers"
import Trackers from 'lib/trackers'

function marker (point) {
  const lng = +point.getAttribute('data-lng')
  const lat = +point.getAttribute('data-lat')

  return new maplibre.Marker().setLngLat({ lng, lat })
}

export default class extends Controller {
  static targets = ['longitudeField', 'latitudeField', 'newPointForm', 'map', 'point', 'userName']
  static values = {
    editable: Boolean,
    layerId: String,
    sessionId: String
  }

  initialize () {
    this.markers = new Map()
    this.lastMoveSent = Date.now()
  }

  connect () {
    this.map = new_map(this.mapTarget)

    this.trackers = new Trackers(this.map)
    this.markers.forEach(marker => marker.addTo(this.map))

    if (this.editableValue){
      this.map.on('click', e => {
        this.longitudeFieldTarget.value = e.lngLat.lng
        this.latitudeFieldTarget.value = e.lngLat.lat
        this.newPointFormTarget.requestSubmit()
      })

      this.map.on('mousemove', e => {
        if ( Date.now() - this.lastMoveSent > 20) {
          this.channel.mouse_moved(e.lngLat)
          this.lastMoveSent = Date.now()
        }
      })
    }

    const _this = this
    this.channel = consumer.subscriptions.create({channel: 'SharePositionChannel', layer: this.layerIdValue}, {
      connected() {
        console.log('connected')
      },
      disconnected() {
        console.log('disconnected')
      },
      received(data) {
        if(data.sessionId !== _this.sessionIdValue) {
          _this.trackers.upsert(data)
        }
      },
      mouse_moved(lngLat) {
        return this.perform('mouse_moved', {
          lngLat,
          name: _this.userNameTarget.value,
          sessionId: _this.sessionIdValue,
          layerId: _this.layerIdValue
        });
      },
    });
  }

  pointTargetConnected (point) {
    const id = point.getAttribute('id')
    const m = marker(point)
    this.markers.set(id, m)
    if (this.map) {
      m.addTo(this.map)
    }
  }

  pointTargetDisconnected (point) {
    const id = point.getAttribute('id')
    const m = this.markers.get(id)
    m.remove()
    this.markers.delete(id)
  }
}
