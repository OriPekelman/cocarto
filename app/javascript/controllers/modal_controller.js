import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['overlay', 'content']

  show ({ params: { id } }) {
    this.contentTarget.innerHTML = document.getElementById(id).innerHTML
    this.overlayTarget.classList.add('modal__overlay--active')
  }

  close () {
    this.overlayTarget.classList.remove('modal__overlay--active')
  }
}
