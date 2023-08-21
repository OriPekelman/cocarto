import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['indicator']
  static values = {
    eventDetailAttribute: String,
    onTitle: String,
    offTitle: String
  }

  indicatorTargetConnected (e) {
    this.#refresh()
  }

  presenceChanged (e) {
    this.presence = e.detail[this.eventDetailAttributeValue]
    this.#refresh()
  }

  #refresh () {
    this.indicatorTarget.dataset.presenceIndicator = this.presence ? 'on' : 'off'
    this.indicatorTarget.title = this.presence ? this.onTitleValue : this.offTitleValue
  }
}
