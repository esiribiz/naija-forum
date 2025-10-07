import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Comments controller connected")
  }
  
  // Simple method to clear all reply forms
  clearAllReplyForms() {
    document.querySelectorAll('.reply-form').forEach(form => {
      form.innerHTML = ''
    })
  }
}
