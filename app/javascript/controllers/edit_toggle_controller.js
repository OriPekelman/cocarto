import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ["text", "form"]
  edit () {
    this.textTarget.classList.add('is-hidden')
    this.formTarget.classList.remove('is-hidden')
  }
  submit () {
    this.formTarget.requestSubmit()
  }
}

