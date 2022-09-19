import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect () {
    // Loading time optimization based on
    // https://patdavid.net/2019/02/displaying-a-big-html-table/
    this.element.style.display = 'inline-block'
  }
}
