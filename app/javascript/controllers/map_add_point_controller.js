import { Controller } from '@hotwired/stimulus'

import { newMap, geocoderApi } from 'lib/map_helpers'
import MaplibreGeocoder from '@maplibre/maplibre-gl-geocoder'
import maplibregl from 'maplibre-gl'

export default class extends Controller {
  static targets = ['map', 'geojson']

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
    this.map = newMap(this.mapTarget)
    this.map.on('moveend', () => this.#setGeojson())

    this.map.addControl(
      new MaplibreGeocoder(geocoderApi, {
        maplibregl
      })
    )
  }
}
