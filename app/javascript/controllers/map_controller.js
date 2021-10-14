import { Controller } from '@hotwired/stimulus'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'

function popup (lngLat) {
  const formTemplate = document.getElementById('points-form-template')
  const clone = document.importNode(formTemplate.content, true)

  return new maplibregl.Popup({ anchor: 'bottom' })
    .setLngLat(lngLat)
    .setDOMContent(clone)
    .setMaxWidth('300px')
}

function marker (point) {
  const lng = +point.getAttribute('data-lng')
  const lat = +point.getAttribute('data-lat')

  return new maplibregl.Marker().setLngLat({ lng, lat })
}

export default class extends Controller {
  static targets = [ "longitudeDisplay", "longitudeField", "latitudeDisplay", "latitudeField", "map", "point" ]

  initialize () {
    this.markers = new Map()
  }

  connect () {
    this.map = new maplibregl.Map({
      container: this.mapTarget.id,
      style:
        'https://api.maptiler.com/maps/basic/style.json?key=rF1iMNeNc3Eh3ES7Ke8H',
      center: [0, 0],
      zoom: 1
    })

    this.markers.forEach(marker => marker.addTo(this.map))

    this.map.on('click', e => {
      popup(e.lngLat).addTo(this.map)
      this.longitudeDisplayTarget.innerText = e.lngLat.lng.toFixed(5)
      this.longitudeFieldTarget.value = e.lngLat.lng
      this.latitudeDisplayTarget.innerText = e.lngLat.lat.toFixed(5)
      this.latitudeFieldTarget.value = e.lngLat.lat
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
