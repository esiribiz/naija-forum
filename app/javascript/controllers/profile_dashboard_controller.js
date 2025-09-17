import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "content"]
  static values = { activeTab: String }

  connect() {
    console.log("Profile dashboard controller connected")
    // Set default active tab if none specified
    if (!this.activeTabValue) {
      this.activeTabValue = "overview"
    }
    this.showActiveTab()
  }

  // Switch to a specific tab
  switchTab(event) {
    event.preventDefault()
    const tabName = event.currentTarget.dataset.tab
    this.activeTabValue = tabName
    this.showActiveTab()
    
    // Update URL without page reload
    const url = new URL(window.location)
    url.searchParams.set('tab', tabName)
    window.history.pushState({}, '', url)
  }

  // Show the active tab and hide others
  showActiveTab() {
    // Update tab buttons
    this.tabTargets.forEach(tab => {
      const tabName = tab.dataset.tab
      if (tabName === this.activeTabValue) {
        // Active tab styling
        tab.classList.remove("text-gray-600", "bg-white", "hover:text-gray-800")
        tab.classList.add("text-green-600", "bg-green-50", "border-green-200")
      } else {
        // Inactive tab styling
        tab.classList.remove("text-green-600", "bg-green-50", "border-green-200")
        tab.classList.add("text-gray-600", "bg-white", "hover:text-gray-800")
      }
    })

    // Update content panels
    this.contentTargets.forEach(content => {
      const contentTab = content.dataset.tab
      if (contentTab === this.activeTabValue) {
        content.classList.remove("hidden")
        content.classList.add("block")
      } else {
        content.classList.remove("block")
        content.classList.add("hidden")
      }
    })

    console.log(`Switched to tab: ${this.activeTabValue}`)
  }

  // Handle browser back/forward navigation
  activeTabValueChanged() {
    this.showActiveTab()
  }
}