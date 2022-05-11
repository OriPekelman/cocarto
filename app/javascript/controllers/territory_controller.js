import maplibre from 'maplibre-gl'
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['map', 'geometry']

  connect () {
    this.map = new maplibre.Map({
      container: this.mapTarget.id,
      style:
        'https://api.maptiler.com/maps/basic/style.json?key=rF1iMNeNc3Eh3ES7Ke8H',
      center: [0, 0],
      zoom: 1,
      attributionControl: false,
    }).addControl(new maplibre.AttributionControl({
      customAttribution: '<a href="https://www.maptiler.com/copyright/" target="_blank">&copy; MapTiler</a> <a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap contributors</a>',
      compact: false
    }));

    this.map.on('load', () => {
      for(const geometry of this.geometryTargets) {
        const id = geometry.getAttribute('id')
        const geojson = JSON.parse(geometry.innerText)
        this.map.addSource(id, {
          'type': 'geojson',
          'data': geojson,
        })

        this.map.addLayer({
          'id': id,
          'type': 'line',
          'source': id,
          'paint': {
            'line-color': '#888',
            'line-width': 2
          }
        });
      }
    })
  }
}
