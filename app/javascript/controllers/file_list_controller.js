import { Controller } from '@hotwired/stimulus'

// When styling <input type="file">
// we need a bit of JS to display what files will be submitted
export default class extends Controller {
  static targets = ['list', 'input']

  update () {
    const files = Array.from(this.inputTarget.files)
    this.listTarget.innerHTML = files.map(file => file.name).join(', ')
  }
}
