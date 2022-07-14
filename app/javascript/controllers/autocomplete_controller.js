import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['searchInput', 'selected']

  input ({ target }) {
    if (this.searchInputTarget.value.length >= 2) {
      this.dispatch('input')

      target.form.requestSubmit()
    }
  }

  selected ({ params }) {
    this.selectedTarget.value = params.id
    this.searchInputTarget.value = params.value
    this.dispatch('selected')
    this.searchInputTarget.focus()
    this.hide()
  }
}
