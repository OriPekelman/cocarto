import maplibre from 'maplibre-gl'
import { Controller } from '@hotwired/stimulus'

import consumer from "../channels/consumer"

function marker (point) {
  const lng = +point.getAttribute('data-lng')
  const lat = +point.getAttribute('data-lat')

  return new maplibre.Marker().setLngLat({ lng, lat })
}

function otherPointer (lngLat, name) {
  var el = document.createElement('div')
  el.innerText = name ? name : 'Anonymous'

  return new maplibre.Marker(el).setLngLat(lngLat)
}

export default class extends Controller {
  static targets = ['longitudeField', 'latitudeField', 'newPointForm', 'map', 'point', 'userName', 'sessionId', 'layerId']

  initialize () {
    this.markers = new Map()
    this.otherPositions = new Map()
    this.sessionId = this.sessionIdTarget.value
    this.layerId = this.layerIdTarget.value
    this.lastMoveSent = Date.now()
  }

  connect () {
    this.map = new maplibre.Map({
      container: this.mapTarget.id,
      style:
        'https://api.maptiler.com/maps/basic/style.json?key=rF1iMNeNc3Eh3ES7Ke8H',
      center: [0, 0],
      zoom: 1
    })

    this.markers.forEach(marker => marker.addTo(this.map))

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

    const _this = this
    this.channel = consumer.subscriptions.create({channel: 'SharePositionChannel', layer: this.layerId}, {
      connected() {
        console.log('connected')
      },
      disconnected() {
        console.log('disconnected')
      },
      received(data) {
        if(data.sessionId !== _this.sessionId) {
          data.timeout = true
          if (_this.otherPositions.has (data.sessionId)) {
            _this.updateOtherPosition(data)
          } else {
            _this.addOtherPosition(data)
          }
        }
      },
      mouse_moved(lngLat) {
        return this.perform('mouse_moved', {
          lngLat,
          name: _this.userNameTarget.value,
          sessionId: _this.sessionId,
          layerId: _this.layerId
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

  updateOtherPosition (params) {
    let other = this.otherPositions.get(params.sessionId)
    if (other.name !== params.name) {
      this.deleteOtherPosition(params.sessionId)
      this.addOtherPosition(params)
    } else {
      other.marker.setLngLat(params.lngLat)
    }
  }

  deleteOtherPosition (sessionId) {
    let other = this.otherPositions.get(sessionId)
    other.marker.remove()
    this.otherPositions.delete(sessionId)
  }

  addOtherPosition ({sessionId, lngLat, name, timeout}) {
    if (this.map) {
      const marker = otherPointer(lngLat, name)
      marker.addTo(this.map)
      this.otherPositions.set(sessionId, {
        name,
        marker,
      })

      if (timeout) {
        window.setTimeout(() => this.markOutdated(sessionId), 10 * 1000);
      }
    }
  }

  markOutdated (sessionId) {
    console.log('outadet', sessionId)
    const other = this.otherPositions.get(sessionId)
    const lngLat = other.marker.getLngLat()
    const name = other.name + ' (lost)'
    this.updateOtherPosition({sessionId, lngLat, name, timeout: false})
    window.setTimeout( () => this.deleteOtherPosition(sessionId), 10 * 000);
  }
}
