import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
static targets = ["replyForm", "replyButton"]

toggleReplyForm(event) {
    event.preventDefault()
    const commentId = event.currentTarget.dataset.commentId
    const replyForm = document.querySelector(`#comment_${commentId}_reply_form`)
    
    // Hide all other visible reply forms first
    document.querySelectorAll('.reply-form').forEach(form => {
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
formSuccess() {
    this.element.reset()
    // Hide the reply form if this was a reply
    const replyForm = this.element.closest('.reply-form')
    if (replyForm) {
    replyForm.classList.add('hidden')
    }
}

// Handle validation errors
formError() {
    console.log("Form submission failed")
}
}
