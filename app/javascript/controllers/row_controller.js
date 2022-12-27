import { Controller } from '@hotwired/stimulus'
import maplibre from 'maplibre-gl'

export default class extends Controller {
  static targets = ['form', 'geojson']
  static outlets = ['map']
  static values = {
    lngMin: Number,
    lngMax: Number,
    latMin: Number,
    latMax: Number,
    properties: Object
  }

  connect () {
    // Small hack inspired by https://dev.to/leastbad/the-best-one-line-stimulus-power-move-2o90
    this.element.rowController = this
    this.dirty = false
  }

  setDirty () {
    this.dirty = true
  }

  save (event) {
    if (this.dirty || event.params.autosave) {
      this.formTarget.requestSubmit()
    }
  }

  geojson () {
    return JSON.parse(this.geojsonTarget.value)
  }

  bounds () {
    const sw = new maplibre.LngLat(this.lngMinValue, this.latMinValue)
    const ne = new maplibre.LngLat(this.lngMaxValue, this.latMaxValue)

    return new maplibre.LngLatBounds(sw, ne)
  }

  update (geojson) {
    this.geojsonTarget.value = JSON.stringify(geojson)
    this.formTarget.requestSubmit()
  }

  zoomToFeature () {
    this.mapOutlet.mapState.setVisibleBounds(this.bounds())
  }
}
