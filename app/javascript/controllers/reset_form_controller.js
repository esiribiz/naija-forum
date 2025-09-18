import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  reset(event) {
    // Reset the form after successful turbo submission
    const form = event.target
    if (form && typeof form.reset === 'function') {
      form.reset()
    }
  }
}