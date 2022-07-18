import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form', 'submit', 'input']

  selected () {
    this.submitTarget.removeAttribute('disabled')
    this.submitTarget.focus()
  }

  save () {
    this.submitTarget.setAttribute('disabled', true)
    // When disabling the submit button, it won’t submit, that’s why we do it by hand
    this.formTarget.requestSubmit()
    this.inputTarget.value = ''
    this.inputTarget.focus()
  }
}
