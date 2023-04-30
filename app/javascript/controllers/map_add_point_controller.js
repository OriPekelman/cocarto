import { Controller } from '@hotwired/stimulus'
import maplibregl from 'maplibre-gl'

import { newMap, newGeolocateControl } from 'lib/map_helpers'

export default class extends Controller {
  static targets = ['map', 'geojson']
  static values = {
    defaultLatitude: Number,
    defaultLongitude: Number,
    defaultZoom: Number,
    styleUrl: String
  }

  connect () {
    this.#initMap()
    this.#setGeojson()
  }

  #setGeojson () {
    const { lng, lat } = this.map.getCenter()
    const geojson = { type: 'Point', coordinates: [lng, lat] }
    this.geojsonTarget.value = JSON.stringify(geojson)
  }

  // Private functions
  #initMap () {
    this.map = newMap(this.mapTarget, [this.defaultLongitudeValue, this.defaultLatitudeValue], this.defaultZoomValue, this.styleUrlValue)
    this.#setGeojson()
    this.map.on('moveend', () => this.#setGeojson())

    const geolocate = newGeolocateControl()
    this.map.addControl(geolocate)
    this.map.addControl(new maplibregl.NavigationControl({
      showCompass: false
    }))
    this.map.on('load', () => geolocate.trigger())
  }
}
