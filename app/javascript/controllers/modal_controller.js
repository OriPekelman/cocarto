import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['content']

  close (event) {
    event.preventDefault()
    this.element.parentElement.removeAttribute('src')
    this.element.remove()
  }

  escape (event) {
    // This method only exists to work around a bug between cuprite, chrome devtools, and stimulus.
    // 1. When simulating user input for Capybara’s fill_in, cuprite generates a UIEvent for each keydown
    //    It does this in its javascript that’s inserted in the page. See the method keyupdowned in index.js in cuprite’s source.
    // 2. In modal_component.html.erb, we bind `keydown.esc` to our #close method.
    // 3. Stimulus receives the event, but since it is not an actual KeyboardEvent,
    //    it bypasses the `isFilterTarget` method that should check the key being pressed
    //    and calls our method directly.
    // Additionally, I can’t use instanceof KeyboardEvent because standardjs complains.
    if (Object.prototype.toString.call(event) === '[object KeyboardEvent]') {
      this.close(event)
    }
  }

  submitEnd (event) {
    if (event.detail.success) {
      this.close(event)
    }
  }
}
