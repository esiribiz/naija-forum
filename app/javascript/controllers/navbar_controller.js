import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu", "mobileMenuButton", "profileDropdown", "dropdownArrow"]

  connect() {
    console.log("Navbar controller connected")
    document.addEventListener("click", this.closeProfileDropdown.bind(this))
  }

  toggleMobileMenu() {
    console.log("Toggling mobile menu")
    this.mobileMenuTarget.classList.toggle("hidden")
    
    // Optionally add an active state to the mobile menu button
    if (this.hasMobileMenuButtonTarget) {
      this.mobileMenuButtonTarget.classList.toggle("active")
    }
  }

  toggleProfileDropdown(event) {
    event.stopPropagation() // Prevents closing when clicking the button
    console.log("Toggling profile dropdown")

    if (this.hasProfileDropdownTarget) {
      this.profileDropdownTarget.classList.toggle("opacity-0")
      this.profileDropdownTarget.classList.toggle("invisible")
    }
    
    this.rotateDropdownArrow()
  }

  closeProfileDropdown(event) {
    if (
      this.hasProfileDropdownTarget && 
      !this.profileDropdownTarget.contains(event.target) &&
      !event.target.closest('[data-action="click->navbar#toggleProfileDropdown"]')
    ) {
      this.profileDropdownTarget.classList.add("opacity-0", "invisible")
      this.rotateDropdownArrow(false)
    }
  }

  rotateDropdownArrow(showDropdown = null) {
    if (!this.hasDropdownArrowTarget) return
    
    if (showDropdown === null) {
      // Toggle rotation based on dropdown visibility
      if (this.profileDropdownTarget.classList.contains("opacity-0")) {
        this.dropdownArrowTarget.classList.remove("rotate-180")
      } else {
        this.dropdownArrowTarget.classList.add("rotate-180")
      }
    } else if (showDropdown) {
      this.dropdownArrowTarget.classList.add("rotate-180")
    } else {
      this.dropdownArrowTarget.classList.remove("rotate-180")
    }
  }
}
