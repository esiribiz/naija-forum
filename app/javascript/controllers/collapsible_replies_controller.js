import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapsible-replies"
export default class extends Controller {
  static targets = ["repliesContainer", "toggleButton", "replyCount"]

  connect() {
    console.log('Collapsible replies controller connected!')
    this.collapsed = false
    this.updateButtonText()
  }

  toggle() {
    console.log('Toggle clicked!')
    this.collapsed = !this.collapsed
    
    if (this.collapsed) {
      this.collapse()
    } else {
      this.expand()
    }
    
    this.updateButtonText()
  }

  collapse() {
    if (this.hasRepliesContainerTarget) {
      this.repliesContainerTarget.style.display = 'none'
    }
  }

  expand() {
    if (this.hasRepliesContainerTarget) {
      this.repliesContainerTarget.style.display = 'block'
    }
  }

  updateButtonText() {
    if (!this.hasToggleButtonTarget) return
    
    const icon = this.collapsed ? '➕' : '−'
    const iconSpan = this.toggleButtonTarget.querySelector('span:first-child')
    if (iconSpan) {
      iconSpan.textContent = icon
    }
  }
}
