// app/javascript/controllers/comment_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggleReplyForm(event) {
    const id = event.currentTarget.dataset.commentId
    const form = document.getElementById(`reply-form-${id}`)
    if (form) form.classList.toggle("hidden")
  }

  cancelReplyForm(event) {
    const id = event.currentTarget.dataset.commentId
    const form = document.getElementById(`reply-form-${id}`)
    if (form) form.classList.add("hidden")
  }
}
