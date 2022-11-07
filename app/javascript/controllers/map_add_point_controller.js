import { Controller } from '@hotwired/stimulus'

import { newMap } from 'lib/map_helpers'
import maplibregl from 'maplibre-gl'

export default class extends Controller {
  static targets = ['map', 'geojson']
  static values = {
    defaultLatitude: Number,
    defaultLongitude: Number,
    defaultZoom: Number
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
    this.map = newMap(this.mapTarget, [this.defaultLongitudeValue, this.defaultLatitudeValue], this.defaultZoomValue)
    this.#setGeojson()
    this.map.on('moveend', () => this.#setGeojson())

    const geolocate = new maplibregl.GeolocateControl({
      positionOptions: {
        enableHighAccuracy: true
      },
      trackUserLocation: true
    })

    this.map.addControl(geolocate)

    this.map.on('load', function () {
      geolocate.trigger()
    })
  }
}
