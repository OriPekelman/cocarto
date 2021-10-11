import { Controller } from '@hotwired/stimulus'
import maplibregl from 'maplibre-gl'
import 'maplibre-gl/dist/maplibre-gl.css'
import Map from 'maplibre-gl/types/ui/map'
import LngLat from 'maplibre-gl/types/geo/lng_lat'

function popup(lngLat: LngLat) {
  const markerHeight = 50, markerRadius = 10, linearOffset = 25;

  return new maplibregl.Popup({offset: [0, -markerHeight], className: 'my-class', anchor: 'bottom'})
  .setLngLat(lngLat)
  .setHTML("<h1>Hello World!</h1>")
  .setMaxWidth("300px");
}

export default class extends Controller {
  map: Map

  connect() {
    this.map = new maplibregl.Map({
      container: this.element.id,
      style:
        'https://api.maptiler.com/maps/basic/style.json?key=rF1iMNeNc3Eh3ES7Ke8H',
      center: [0, 0],
      zoom: 1,
    })
  }
}
