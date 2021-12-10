import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  toggle () {
    console.log('toggle')
    this.element.classList.toggle('is-active')
  }
}
