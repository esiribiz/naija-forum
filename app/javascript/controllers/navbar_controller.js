import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu", "mobileMenuButton", "profileDropdown", "dropdownArrow"]
  static classes = ["visible", "hidden", "rotate"]

  initialize() {
    this.boundClickOutside = this.handleClickOutside.bind(this)
  }

  connect() {
    console.log("Navbar controller connected")
    document.addEventListener("click", this.boundClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
  }

  toggleMobileMenu() {
    console.log("Toggling mobile menu")
    
    // Check if the menu is currently hidden
    const isHidden = this.mobileMenuTarget.classList.contains("hidden") || 
                     this.mobileMenuTarget.classList.contains("opacity-0") ||
                     this.mobileMenuTarget.classList.contains("invisible");
    
    if (isHidden) {
      // Show mobile menu
      this.mobileMenuTarget.classList.remove("hidden", "opacity-0", "invisible")
      this.mobileMenuTarget.classList.add("show")
    } else {
      // Hide mobile menu
      this.mobileMenuTarget.classList.add("opacity-0", "invisible")
      // Add hidden class after transition completes
      setTimeout(() => {
        this.mobileMenuTarget.classList.add("hidden")
      }, 300) // Match this to your CSS transition duration
      this.mobileMenuTarget.classList.remove("show")
    }
    
    // Optionally add an active state to the mobile menu button
    if (this.hasMobileMenuButtonTarget) {
      this.mobileMenuButtonTarget.classList.toggle("active")
    }
  }

  toggleProfileDropdown(event) {
    event.stopPropagation() // Prevents closing when clicking the button
    console.log("Toggling profile dropdown")

    if (this.hasProfileDropdownTarget) {
      const isHidden = this.isDropdownHidden()
      
      if (isHidden) {
        this.showDropdown()
      } else {
        this.hideDropdown()
      }
    }
  }

  showDropdown() {
    this.profileDropdownTarget.classList.remove("hidden")
    // Trigger a reflow to ensure the transition works
    this.profileDropdownTarget.offsetHeight
    this.profileDropdownTarget.classList.remove("opacity-0", "translate-y-2")
    this.profileDropdownTarget.classList.add("opacity-100", "translate-y-0")
    this.rotateDropdownArrow(true)
  }

  hideDropdown() {
    this.profileDropdownTarget.classList.add("opacity-0", "translate-y-2")
    this.profileDropdownTarget.classList.remove("opacity-100", "translate-y-0")
    
    // Wait for the transition to complete before hiding
    setTimeout(() => {
      if (this.isDropdownHidden()) {
        this.profileDropdownTarget.classList.add("hidden")
      }
    }, 300)
    
    this.rotateDropdownArrow(false)
  }

  isDropdownHidden() {
    return this.profileDropdownTarget.classList.contains("hidden") || 
           this.profileDropdownTarget.classList.contains("opacity-0")
  }

  handleClickOutside(event) {
    if (
      this.hasProfileDropdownTarget && 
      !this.element.contains(event.target) &&
      !this.isDropdownHidden()
    ) {
      this.hideDropdown()
    }
  }

  rotateDropdownArrow(showDropdown = null) {
    if (!this.hasDropdownArrowTarget) return
    
    const rotateClass = "rotate-180"
    if (showDropdown === null) {
      this.dropdownArrowTarget.classList.toggle(rotateClass)
    } else if (showDropdown) {
      this.dropdownArrowTarget.classList.add(rotateClass)
    } else {
      this.dropdownArrowTarget.classList.remove(rotateClass)
    }
  }

  // Utility method to apply transitions smoothly
  applyTransition(element, addClass, removeClass) {
    if (addClass) element.classList.add(...addClass)
    if (removeClass) element.classList.remove(...removeClass)
  }
}
