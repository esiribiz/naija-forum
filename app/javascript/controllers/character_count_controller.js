import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["counter"]
  
  connect() {
    const textarea = this.element.querySelector("textarea")
    if (textarea) {
      textarea.addEventListener("input", this.updateCounter.bind(this))
      this.updateCounter()
    }
  }

  updateCounter() {
    const textarea = this.element.querySelector("textarea")
    if (textarea && this.hasCounterTarget) {
      const count = textarea.value.length
      const maxLength = textarea.maxLength || 500
      
      this.counterTarget.textContent = `${count}/${maxLength}`
      
      // Change color based on usage
      if (count > maxLength * 0.9) {
        this.counterTarget.classList.add("text-red-500")
        this.counterTarget.classList.remove("text-yellow-500", "text-gray-400")
      } else if (count > maxLength * 0.8) {
        this.counterTarget.classList.add("text-yellow-500")
        this.counterTarget.classList.remove("text-red-500", "text-gray-400")
      } else {
        this.counterTarget.classList.add("text-gray-400")
        this.counterTarget.classList.remove("text-red-500", "text-yellow-500")
      }
    }
  }
}