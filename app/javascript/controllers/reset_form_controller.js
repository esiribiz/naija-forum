import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  reset(event) {
    // Reset the form after successful turbo submission
    const form = event.target
    if (form && typeof form.reset === 'function') {
      form.reset()
    }
    
    // If this is a reply form, also clear the container
    const replyForm = form.closest('.reply-form-container')
    if (replyForm && replyForm.parentElement) {
      // Clear the reply form container after successful submission
      setTimeout(() => {
        replyForm.parentElement.innerHTML = ''
      }, 100)
    }
  }
  
  clearReplyForm(event) {
    // Clear reply form when cancel is clicked
    event.preventDefault()
    const replyFormContainer = event.target.closest('.reply-form-container')
    if (replyFormContainer && replyFormContainer.parentElement) {
      replyFormContainer.parentElement.innerHTML = ''
    }
  }
}
