import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu", "mobileMenuButton", "profileDropdown", "dropdownArrow"]

  connect() {
    console.log("Navbar controller connected")
    document.addEventListener("click", this.closeProfileDropdown.bind(this))
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
      const isHidden = this.profileDropdownTarget.classList.contains("hidden") || 
                       this.profileDropdownTarget.classList.contains("opacity-0") ||
                       this.profileDropdownTarget.classList.contains("invisible");
      
      if (isHidden) {
        // Show dropdown
        this.profileDropdownTarget.classList.remove("hidden", "opacity-0", "invisible")
        this.profileDropdownTarget.classList.add("show")
      } else {
        // Hide dropdown
        this.profileDropdownTarget.classList.add("opacity-0", "invisible")
        // Add hidden class after transition completes
        setTimeout(() => {
          this.profileDropdownTarget.classList.add("hidden")
        }, 300) // Match this to your CSS transition duration
        this.profileDropdownTarget.classList.remove("show")
      }
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
      setTimeout(() => {
        this.profileDropdownTarget.classList.add("hidden")
      }, 300) // Match this to your CSS transition duration
      this.profileDropdownTarget.classList.remove("show")
      this.rotateDropdownArrow(false)
    }
  }

  rotateDropdownArrow(showDropdown = null) {
    if (!this.hasDropdownArrowTarget) return
    
    if (showDropdown === null) {
      // Toggle rotation based on dropdown visibility
      // Check for visibility state to determine if dropdown is visible
      const isHidden = this.profileDropdownTarget.classList.contains("hidden") || 
                       this.profileDropdownTarget.classList.contains("opacity-0") ||
                       this.profileDropdownTarget.classList.contains("invisible");
      
      if (!isHidden) {
        this.dropdownArrowTarget.classList.add("rotate-180")
      } else {
        this.dropdownArrowTarget.classList.remove("rotate-180")
      }
    } else if (showDropdown) {
      this.dropdownArrowTarget.classList.add("rotate-180")
    } else {
      this.dropdownArrowTarget.classList.remove("rotate-180")
    }
  }
}
