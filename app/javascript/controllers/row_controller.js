import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form', 'geojson']
  static values = {
    'author': String
  }

  connect () {
    // Small hack inspired by https://dev.to/leastbad/the-best-one-line-stimulus-power-move-2o90
    this.element.rowController = this
    this.element.dataset.mapTarget = 'row'
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

  disableInput(currentUser, role) {
    const canEdit = role === 'owner' || role === 'editor' || (role === 'contributor' && currentUser === this.authorValue)
    if(!canEdit) {
      for(const input of  this.element.getElementsByTagName('input')) {
        input.setAttribute("disabled", true)
      }
      for(const input of  this.element.getElementsByTagName('button')) {
        input.setAttribute("disabled", true)
      }
    }
  }
}
