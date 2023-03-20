import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['content']

  close () {
    this.element.parentElement.removeAttribute('src')
    this.element.remove()
  }

  closeFromOutside (event) {
    if (!this.contentTarget.contains(event.target)) {
      this.close()
    }
  }

  submitEnd (e) {
    if (e.detail.success) {
      this.close()
    }
  }
}
