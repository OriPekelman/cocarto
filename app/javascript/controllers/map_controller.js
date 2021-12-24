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

    this.map.on('mousemove', e => this.channel.mouse_moved(e.lngLat))

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

  updateOtherPosition ({sessionId, lngLat, name}) {
    let other = this.otherPositions.get(sessionId)
    if (other.name !== name) {
      other.marker.remove()
      this.otherPositions.delete(sessionId)
      this.addOtherPosition({sessionId, lngLat, name})
    } else {
      other.marker.setLngLat(lngLat)
    }
  }

  addOtherPosition ({sessionId, lngLat, name}) {
    if (this.map) {
      const marker = otherPointer(lngLat, name)
      marker.addTo(this.map)
      this.otherPositions.set(sessionId, {
        name,
        marker,
      })
    }
  }
}
