import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['searchInput', 'suggestion', 'suggestionList', 'selected']

  input({target}) {
    if (this.searchInputTarget.value.length >= 2) {
      this.suggestionListTarget.classList.remove('is-hidden')

      target.form.requestSubmit()
      console.log('input')
    }
  }

  selected({params}) {
    console.log('selected')
    this.selectedTarget.value = params.id
    this.searchInputTarget.value = params.value
    this.dispatch('selected')
    this.searchInputTarget.focus()
    this.hide()
  }

  hide() {
    this.suggestionListTarget.classList.add('is-hidden')
  }
}
