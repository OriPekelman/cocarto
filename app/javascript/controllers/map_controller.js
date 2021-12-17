import maplibre from 'maplibre-gl'
import { Controller } from '@hotwired/stimulus'

function marker (point) {
  const lng = +point.getAttribute('data-lng')
  const lat = +point.getAttribute('data-lat')

  return new maplibre.Marker().setLngLat({ lng, lat })
}

export default class extends Controller {
  static targets = ['longitudeField', 'latitudeField', 'newPointForm', 'map', 'point']

  initialize () {
    this.markers = new Map()
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
