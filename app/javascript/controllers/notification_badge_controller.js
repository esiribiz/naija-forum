import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["navbarBadge", "mobileBadge", "sidebarBadge"]

  connect() {
    // Listen for notification events
    document.addEventListener('notifications:updated', this.handleNotificationUpdate.bind(this))
    document.addEventListener('notifications:cleared', this.clearAllBadges.bind(this))
    document.addEventListener('notifications:markAllRead', this.clearAllBadges.bind(this))
    document.addEventListener('notifications:viewed', this.clearAllBadges.bind(this))
    
    // Listen for page visits to the notifications page
    document.addEventListener('turbo:visit', this.handlePageVisit.bind(this))
  }

  disconnect() {
    document.removeEventListener('notifications:updated', this.handleNotificationUpdate.bind(this))
    document.removeEventListener('notifications:cleared', this.clearAllBadges.bind(this))
    document.removeEventListener('notifications:markAllRead', this.clearAllBadges.bind(this))
    document.removeEventListener('notifications:viewed', this.clearAllBadges.bind(this))
    document.removeEventListener('turbo:visit', this.handlePageVisit.bind(this))
  }

  handlePageVisit(event) {
    // If user visits notifications page, mark notifications as viewed and update badges
    if (event.detail.url && event.detail.url.includes('/notifications')) {
      setTimeout(() => {
        this.updateBadgeCount(0)
      }, 100) // Small delay to ensure page load
    }
  }

  handleNotificationUpdate(event) {
    const count = event.detail.count
    this.updateBadgeCount(count)
  }

  clearAllBadges() {
    this.updateBadgeCount(0)
  }

  updateBadgeCount(count) {
    // Update navbar badge
    const navbarBadge = document.getElementById('navbar-notification-badge')
    if (navbarBadge) {
      if (count > 0) {
        navbarBadge.textContent = count > 99 ? '99+' : count
        navbarBadge.style.display = 'flex'
      } else {
        navbarBadge.style.display = 'none'
      }
    }

    // Update mobile badge
    const mobileBadge = document.getElementById('mobile-notification-badge')
    if (mobileBadge) {
      if (count > 0) {
        mobileBadge.textContent = count > 99 ? '99+' : count
        mobileBadge.style.display = 'flex'
      } else {
        mobileBadge.style.display = 'none'
      }
    }

    // Update sidebar badge (if present)
    const sidebarBadge = document.getElementById('sidebar-notification-badge')
    if (sidebarBadge) {
      if (count > 0) {
        sidebarBadge.textContent = count
        sidebarBadge.style.display = 'inline-flex'
      } else {
        sidebarBadge.style.display = 'none'
      }
    }
  }

  // Method to manually update count (called from forms)
  updateCount(count) {
    this.updateBadgeCount(count)
  }

  // Method to fetch current count from server
  async fetchAndUpdateCount() {
    try {
      const response = await fetch('/notifications.json')
      if (response.ok) {
        const data = await response.json()
        const unreadCount = data.filter(n => !n.read).length
        this.updateBadgeCount(unreadCount)
      }
    } catch (error) {
      console.error('Error fetching notification count:', error)
    }
  }
}