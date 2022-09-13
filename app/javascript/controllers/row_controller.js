import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form', 'geojson']
  static values = {
    author: String
  }

  connect () {
    // Small hack inspired by https://dev.to/leastbad/the-best-one-line-stimulus-power-move-2o90
    this.element.rowController = this
    this.element.dataset.mapTarget = 'row'
    this.dirty = false
  }

  setDirty () {
    this.dirty = true
  }

  save () {
    if (this.dirty) {
      this.formTarget.requestSubmit()
    }
  }

  geojson () {
    return JSON.parse(this.geojsonTarget.value)
  }

  update (geojson) {
    this.geojsonTarget.value = JSON.stringify(geojson)
    this.formTarget.requestSubmit()
  }

  updateEditable (currentUser, role) {
    const canEdit = role === 'owner' || role === 'editor' || (role === 'contributor' && currentUser === this.authorValue)
    for (const input of this.element.getElementsByTagName('input')) {
      if (canEdit) {
        input.removeAttribute('disabled')
      } else {
        input.setAttribute('disabled', true)
      }
    }
    for (const button of this.element.getElementsByTagName('button')) {
      if (canEdit) {
        button.removeAttribute('disabled')
      } else {
        button.setAttribute('disabled', true)
      }
    }
  }
}
