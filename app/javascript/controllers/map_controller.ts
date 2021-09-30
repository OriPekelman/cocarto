import { Controller } from '@hotwired/stimulus'
import maplibregl from 'maplibre-gl'
import map_t from 'maplibre-gl/types/ui/map'

export default class extends Controller {
  map: map_t

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
