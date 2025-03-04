import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["replyForm", "replyButton"]
  static values = { }
  static params = ["commentId"]
  toggleReplyForm(event) {
    event.preventDefault()
    const commentId = this.commentIdParam
    
    // Find the reply form for this comment using the ID
    const replyForm = this.replyFormTargets.find(form => form.id === `reply_form_${commentId}`)
    
    // Hide all other visible reply forms first
    this.replyFormTargets.forEach(form => {
      if (form !== replyForm && !form.classList.contains('hidden')) {
        form.classList.add('hidden')
      }
    })

    // Toggle the clicked reply form
    if (replyForm) {
      replyForm.classList.toggle('hidden')
      
      // Focus the textarea when showing the form
      if (!replyForm.classList.contains('hidden')) {
        const textarea = replyForm.querySelector('textarea')
        if (textarea) {
          textarea.focus()
        }
      }
    }
  }

  // Reset form after successful submission
  formSuccess(event) {
    const form = event.target
    
    // Reset the form
    if (form && typeof form.reset === 'function') {
      form.reset()
    }
    
    // Hide the reply form if this was a reply
    const replyForm = form.closest('.reply-form')
    if (replyForm) {
      replyForm.classList.add('hidden')
    }
    
    // Clear any validation errors that might be displayed
    const errorElements = form.querySelectorAll('.field_with_errors')
    errorElements.forEach(el => {
      el.classList.remove('field_with_errors')
    })
  }

  // Handle validation errors
  formError(event) {
    console.log("Form submission failed", event)
    
    // Add a visual indicator that there was a problem
    const form = event.target
    if (form) {
      const submitButton = form.querySelector('input[type="submit"]')
      if (submitButton) {
        // Flash the button to indicate error
        submitButton.classList.add('error-flash')
        setTimeout(() => {
          submitButton.classList.remove('error-flash')
        }, 1000)
      }
    }
  }
}
