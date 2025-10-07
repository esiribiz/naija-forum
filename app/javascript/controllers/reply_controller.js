import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  static values = { postId: Number, commentId: Number }

  connect() {
    console.log("Reply controller connected")
  }

  showForm() {
    console.log(`Loading reply form for post ${this.postIdValue}, comment ${this.commentIdValue}`)
    
    const url = `/posts/${this.postIdValue}/comments/new?parent_id=${this.commentIdValue}`
    
    fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'text/javascript',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.text())
    .then(script => {
      eval(script)
    })
    .catch(error => {
      console.error('Error loading reply form:', error)
    })
  }

  clearForm() {
    if (this.hasFormTarget) {
      this.formTarget.innerHTML = ''
    }
  }
}