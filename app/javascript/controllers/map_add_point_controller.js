import { Controller } from '@hotwired/stimulus'

import { newMap, newGeolocateControl } from 'lib/map_helpers'

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

    const geolocate = newGeolocateControl()
    this.map.addControl(geolocate)
    this.map.on('load', function () {
      geolocate.trigger()
    })
  }
}
