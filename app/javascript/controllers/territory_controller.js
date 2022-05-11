import { new_map } from 'lib/map_helpers'
import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['map', 'geometry']

  connect () {
    this.map = new_map(this.mapTarget);

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
