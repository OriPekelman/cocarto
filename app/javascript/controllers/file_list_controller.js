import { Controller } from '@hotwired/stimulus'

// When styling <input type="file">
// we need a bit of JS to display what files will be submitted
export default class extends Controller {
  static targets = ['list', 'input', 'dropzone']
  static values = { types: Array }

  update () {
    const files = Array.from(this.inputTarget.files)
    this.listTarget.innerHTML = files.map(file => file.name).join(', ')
  }

  drag_start (e) {
    const isFiles = e.dataTransfer.types.includes('Files')
    if (isFiles) {
      e.preventDefault()
      this.dropzoneTarget.classList.add('button--drop-area-active')
    }
  }

  drag_leave (e) {
    this.dropzoneTarget.classList.remove('button--drop-area-active')
  }

  drop (e) {
    e.preventDefault()

    for (const file of e.dataTransfer.files) {
      if (!this.typesValue.includes(file.type)) {
        this.dropzoneTarget.classList.remove('button--drop-area-active')
        return
      }
    }

    this.inputTarget.files = e.dataTransfer.files
    this.inputTarget.form.requestSubmit()
  }
}
