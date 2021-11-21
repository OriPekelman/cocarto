import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form', 'save']

  initialize () {
    this.modified = false
    this.timer = null
  }

  setModified (event) {
    this.modified = true
    this.saveTarget.disabled = false
  }

  focusIn () {
    if (this.timer !== null) {
      clearTimeout(this.timer)
    }
  }

  focusOut () {
    if (this.modified) {
      this.timer = setTimeout(() => {
        this.setLoading()
        this.formTarget.requestSubmit()
      }, 5000)
    }
  }

  setLoading () {
    this.saveTarget.classList.add('is-loading')
  }
}
