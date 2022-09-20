import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form']

  clear () {
    this.formTarget.reset()
  }
}
