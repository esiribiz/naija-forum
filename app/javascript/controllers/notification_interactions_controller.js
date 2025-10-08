import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []

  connect() {
    this.setupNotificationLinks()
  }

  setupNotificationLinks() {
    // Handle notification view links that should mark as read
    const viewLinks = this.element.querySelectorAll('[data-action="mark-as-read-and-visit"]')
    
    viewLinks.forEach(link => {
      link.addEventListener('click', (event) => {
        const notificationId = link.dataset.notificationId
        const targetUrl = link.href
        
        if (notificationId) {
          // Mark as read first, then navigate
          this.markAsReadAndNavigate(event, notificationId, targetUrl)
        }
      })
    })
  }

  async markAsReadAndNavigate(event, notificationId, targetUrl) {
    // Don't prevent default navigation if marking as read fails
    try {
      // Send mark as read request
      const response = await fetch(`/notifications/${notificationId}/mark_as_read`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken(),
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        // Update the UI to show notification as read
        this.updateNotificationAsRead(notificationId)
        
        // Update notification badges
        this.updateNotificationBadges()
      }
    } catch (error) {
      console.error('Failed to mark notification as read:', error)
    }
    
    // Allow the navigation to continue regardless
  }

  updateNotificationAsRead(notificationId) {
    const notificationElement = document.getElementById(`notification_${notificationId}`)
    if (notificationElement) {
      // Remove unread styling
      notificationElement.classList.remove('unread-notification')
      notificationElement.classList.add('read-notification')
      
      // Remove the unread indicator
      const unreadIndicator = notificationElement.querySelector('.unread-indicator')
      if (unreadIndicator) {
        unreadIndicator.remove()
      }
      
      // Remove the "New" badge
      const newBadge = notificationElement.querySelector('.bg-green-100')
      if (newBadge) {
        newBadge.remove()
      }
      
      // Hide the "Mark as Read" button
      const markAsReadButton = notificationElement.querySelector('form[action*="mark_as_read"]')
      if (markAsReadButton) {
        markAsReadButton.style.display = 'none'
      }
    }
  }

  updateNotificationBadges() {
    // Dispatch custom event to update notification badges
    document.dispatchEvent(new CustomEvent('notifications:updated'))
    
    // Also try to update badge counts directly
    try {
      fetch('/notifications.json')
        .then(response => response.json())
        .then(data => {
          const unreadCount = data.filter(n => !n.read).length
          this.updateBadgeElements(unreadCount)
        })
        .catch(error => console.error('Error fetching notification count:', error))
    } catch (error) {
      console.error('Error updating notification badges:', error)
    }
  }

  updateBadgeElements(count) {
    // Update all notification badge elements
    const badgeSelectors = [
      '.notification-badge',
      '[data-notification-badge]',
      '.notification-count'
    ]
    
    badgeSelectors.forEach(selector => {
      const badges = document.querySelectorAll(selector)
      badges.forEach(badge => {
        if (count > 0) {
          badge.textContent = count
          badge.style.display = 'inline-flex'
        } else {
          badge.style.display = 'none'
        }
      })
    })
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }
}