import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['overlay', 'content']

  contentTargetConnected () {
    this.overlayTarget.classList.add('modal__overlay--active')
  }

  close () {
    this.overlayTarget.classList.remove('modal__overlay--active')
  }

  closeFromOutside (event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }
}
