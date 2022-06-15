import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form', 'longitude', 'latitude', 'polygon']

  connect () {
    // Small hack inspired by https://dev.to/leastbad/the-best-one-line-stimulus-power-move-2o90
    this.element.rowController = this
  }

  save () {
    this.formTarget.requestSubmit()
  }

  getLngLat () {
    return {
      lng: Number(this.longitudeTarget.value),
      lat: Number(this.latitudeTarget.value)
    }
  }

  geojson () {
    return JSON.parse(this.polygonTarget.value)
  }

  dragged ({ lng, lat }) {
    this.longitudeTarget.value = lng
    this.latitudeTarget.value = lat
    this.formTarget.requestSubmit()
  }
}
