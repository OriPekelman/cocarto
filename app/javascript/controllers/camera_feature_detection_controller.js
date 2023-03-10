import { Controller } from '@hotwired/stimulus'

// this controller tests if the browsers supports using the camera for a file input
// most mobile browser do, and no desktop browser

export default class extends Controller {
  connect () {
    const el = document.createElement('input')
    if (el.capture === undefined) {
      this.element.hidden = true
    }
  }
}
