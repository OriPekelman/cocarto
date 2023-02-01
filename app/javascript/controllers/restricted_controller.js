import { Controller } from '@hotwired/stimulus'

// Conditionally enable inputs and other interactive elements based on authorizations and role
export default class extends Controller {
  static targets = ['restricted']
  static values = { role: String }
  // Also needed: data-restricted-authorizations attribute on the restricted target.
  // This is not (yet) supported in Stimulus https://discuss.hotwired.dev/t/stimulus-2-0-values-on-a-target-replacing-dataset/2055/5

  restrictedTargetConnected (restricted) {
    // Compare the requirements on this target and the provided role value
    const authorizations = JSON.parse(restricted.dataset.restrictedAuthorizations)
    // Example:
    // authorizations: [owner, editor, contributor-1234]
    //   role: owner-12345 -> true
    //   role: contributor-12345 -> true
    //   role: contributor-678 -> false
    //   role: viewer -> false
    const enabled = authorizations.some(authorization => this.roleValue.startsWith(authorization))

    // Enable or disable the restricted target
    // https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/disabled
    const supportsDisabling = 'button,fieldset,keygen,optgroup,option,select,textarea,input'
    if (restricted.matches(supportsDisabling)) {
      this.#setEnabled(restricted, enabled)
    }
  }

  #setEnabled (element, enabled) {
    if (enabled) {
      element.removeAttribute('disabled')
      element.hidden = false
    } else {
      element.setAttribute('disabled', true)
      // Some targets will also be hidden (like the delete button)
      if ('restrictedHidden' in element.dataset) {
        element.hidden = true
      }
    }
  }
}
