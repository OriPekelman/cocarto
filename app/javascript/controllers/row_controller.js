import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form', 'save', 'longitude', 'latitude']

  initialize () {
    this.modified = false
    this.timer = null
  }

  connect () {
    // Small hack inspired by https://dev.to/leastbad/the-best-one-line-stimulus-power-move-2o90
    this.element.rowController = this
  }

  setModified (event) {
    this.modified = true
    this.saveTarget.disabled = false
  }

  focusIn () {
    if (this.timer !== null) {
      clearTimeout(this.timer)
    }
  }

  focusOut () {
    if (this.modified) {
      this.timer = setTimeout(() => {
        this.setLoading()
        this.formTarget.requestSubmit()
      }, 5000)
    }
  }

  setLoading () {
    this.saveTarget.classList.add('is-loading')
  }

  getLngLat () {
    return  {
      lng: Number(this.longitudeTarget.value),
      lat: Number(this.latitudeTarget.value),
    }
  }

  dragged ({lng, lat}) {
    this.longitudeTarget.value = lng
    this.latitudeTarget.value = lat
    this.formTarget.requestSubmit()
  }
}
