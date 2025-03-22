import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu", "mobileMenuButton", "profileDropdown", "dropdownArrow"]

  connect() {
    console.log("Navbar controller connected")
    this.boundClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
  }

  closeProfileDropdown() {
    if (!this.isDropdownHidden()) {
      this.hideDropdown()
    }
  }

  toggleProfileDropdown(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (!this.hasProfileDropdownTarget) {
      console.error("Profile dropdown target not found")
      return
    }

    if (this.isDropdownHidden()) {
      this.showDropdown()
    } else {
      this.hideDropdown()
    }
  }

  showDropdown() {
    this.profileDropdownTarget.classList.remove("hidden", "invisible", "opacity-0", "scale-95", "pointer-events-none")
    requestAnimationFrame(() => {
      this.profileDropdownTarget.classList.add("opacity-100", "scale-100", "pointer-events-auto")
      if (this.hasDropdownArrowTarget) {
        this.dropdownArrowTarget.classList.add("rotate-180")
      }
    })
  }

  hideDropdown() {
    this.profileDropdownTarget.classList.remove("opacity-100", "scale-100", "pointer-events-auto")
    this.profileDropdownTarget.classList.add("opacity-0", "scale-95", "pointer-events-none")
    
    setTimeout(() => {
      if (this.hasProfileDropdownTarget) {
        this.profileDropdownTarget.classList.add("hidden", "invisible")
      }
    }, 200)

    if (this.hasDropdownArrowTarget) {
      this.dropdownArrowTarget.classList.remove("rotate-180")
    }
  }

  handleClickOutside(event) {
    if (this.hasProfileDropdownTarget && 
        !this.element.contains(event.target) && 
        !this.isDropdownHidden()) {
      this.hideDropdown()
    }
  }

  isDropdownHidden() {
    return !this.hasProfileDropdownTarget || 
           this.profileDropdownTarget.classList.contains("hidden") || 
           this.profileDropdownTarget.classList.contains("invisible")
  }

  toggleMobileMenu() {
    if (this.hasMobileMenuTarget) {
      const isHidden = this.mobileMenuTarget.classList.contains("hidden")
      
      if (isHidden) {
        this.mobileMenuTarget.classList.remove("hidden", "invisible", "opacity-0")
        requestAnimationFrame(() => {
          this.mobileMenuTarget.classList.add("opacity-100")
        })
      } else {
        this.mobileMenuTarget.classList.remove("opacity-100")
        this.mobileMenuTarget.classList.add("opacity-0")
        setTimeout(() => {
          this.mobileMenuTarget.classList.add("hidden", "invisible")
        }, 200)
      }
    }
  }
}
