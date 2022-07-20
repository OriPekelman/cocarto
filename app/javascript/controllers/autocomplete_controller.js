import { Controller } from '@hotwired/stimulus'
import hotkeys from 'hotkeys-js'

export default class extends Controller {
  static targets = ['searchInput', 'selected', 'suggestion', 'suggestionList']

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
  }

  keyboardSelected (event) {
    // We pressed <enter>
    // We want to avoid submitting a form
    // Hotkeys are removed and won’t catch anything
    event.preventDefault()
    hotkeys.deleteScope('autocomplete')

    const data = this.suggestionTargets.at(parseInt(this.index)).dataset
    this.selectedTarget.value = data.autocompleteIdParam
    this.searchInputTarget.value = data.autocompleteValueParam
    this.dispatch('selected')
  }

  suggestionListTargetConnected () {
    if (this.element.classList.contains('is-active')) {
      this.index = 0
      this.setCurrentSuggestion()

      hotkeys.filter = event => event.target !== this.element
      hotkeys.setScope('autocomplete')
      hotkeys('down', 'autocomplete', event => this.next())
      hotkeys('up', 'autocomplete', event => this.prev())
      hotkeys('enter', 'autocomplete', event => this.keyboardSelected(event))
    }
  }

  suggestionListTargetDisconnected () {
    hotkeys.deleteScope('autocomplete')
  }

  setCurrentSuggestion () {
    this.suggestionTargets.forEach((element, index) => {
      if (index === this.index) {
        element.classList.add('active')
      } else {
        element.classList.remove('active')
      }
    })
  }

  prev () {
    if (this.index-- < 0) {
      this.index = this.suggestionTargets.length - 1
    }
    this.setCurrentSuggestion()
  }

  next () {
    this.index = (this.index + 1) % this.suggestionTargets.length
    this.setCurrentSuggestion()
  }
}
