import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['flash']

  clear () {
    this.flashTargets.forEach(flash => flash.classList.add('flash__item-removing'))
    setTimeout(() => this.flashTargets.forEach(flash => flash.remove()), 300)
  }
}
