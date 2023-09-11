import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form']

  connect () {
    this.dirty = false

    // Small hack inspired by https://dev.to/leastbad/the-best-one-line-stimulus-power-move-2o90
    this.element.rowController = this
    // Ensure rows are connected to RowController (and their .rowController is set) before they are connected to MapController
    this.element.dataset.mapTarget = 'row'

    // Clear any transition class
    setTimeout(() => this.element.classList.remove('layer-table__tr--transition'), 3000)
    setTimeout(() => this.element.classList.remove('layer-table__tr--created'), 1000)
  }

  setDirty () {
    this.dirty = true
  }

  save (event) {
    if (this.dirty || event.params.autosave) {
      this.formTarget.requestSubmit()
    }
  }

  focus () {
    this.highlight({ scroll: false })
  }

  highlight ({ scroll = true } = {}) {
    const currentHighlightedRows = document.querySelectorAll('.layer-table__tr--highlight')
    currentHighlightedRows.forEach(row => row.classList.remove('layer-table__tr--highlight'))
    this.dispatch('highlighted')
    this.element.classList.add('layer-table__tr--highlight')
    if (scroll) {
      this.element.scrollIntoView({ behavior: 'smooth', block: 'center' })
    }
  }
}
