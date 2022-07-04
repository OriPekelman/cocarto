import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form', 'geojson']

  connect () {
    // Small hack inspired by https://dev.to/leastbad/the-best-one-line-stimulus-power-move-2o90
    this.element.pointController = this
    this.element.dataset.mapTarget = 'point'
  }

  save () {
    this.formTarget.requestSubmit()
  }

  geojson () {
    return JSON.parse(this.geojsonTarget.value)
  }

  update (geojson) {
    this.geojsonTarget.value = JSON.stringify(geojson)
    this.formTarget.requestSubmit()
  }
}
