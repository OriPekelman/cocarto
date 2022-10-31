import { newMap } from 'lib/map_helpers'
import { Controller } from '@hotwired/stimulus'
import maplibre from 'maplibre-gl'

export default class extends Controller {
  static targets = ['map', 'geometry']

  connect () {
    this.map = newMap(this.mapTarget, [0, 0], 1)

    this.bounds = null

    this.map.on('load', () => {
      for (const geometry of this.geometryTargets) {
        const id = geometry.getAttribute('id')
        const geojson = JSON.parse(geometry.innerText)
        this.map.addSource(id, {
          type: 'geojson',
          data: geojson
        })

        const bounds = [{
          lng: geometry.getAttribute('data-lng-min'),
          lat: geometry.getAttribute('data-lat-max')
        }, {
          lng: geometry.getAttribute('data-lng-max'),
          lat: geometry.getAttribute('data-lat-min')
        }]
        const newBounds = new maplibre.LngLatBounds(bounds)
        if (this.bounds === null) {
          this.bounds = newBounds
        } else {
          this.bounds = this.bounds.extend(newBounds)
        }

        this.map.addLayer({
          id,
          type: 'line',
          source: id,
          paint: {
            'line-color': '#888',
            'line-width': 2
          }
        })
      }

      this.map.fitBounds(this.bounds, { padding: 20 })
    })
  }
}
