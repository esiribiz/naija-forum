import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    timeout: { type: Number, default: 5000 }
  }

  connect() {
    // Initialize with opacity 0
    this.element.style.opacity = 0
    
    // Add initial opacity to enable fade transition
    requestAnimationFrame(() => {
      this.element.style.opacity = 1
    })
    
    // Add body scroll lock to prevent background scrolling
    document.body.style.overflow = 'hidden'
    
    // Set timeout to hide flash after timeout value (default 5 seconds)
    this.timeout = setTimeout(() => {
      this.close()
    }, this.timeoutValue)
  }
  
  close() {
    // Clear any existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
    
    // Restore body scroll
    document.body.style.overflow = ''
    
    // Add fade out effect
    this.element.style.opacity = 0
    
    // Remove element after animation
    this.element.addEventListener('transitionend', () => {
      this.element.remove()
    }, { once: true })
  }
  
  disconnect() {
    // Clean up timeout if element is removed
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
    
    // Restore body scroll in case element is removed abruptly
    document.body.style.overflow = ''
  }
}
