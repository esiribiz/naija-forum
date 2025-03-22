import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "badge", "list", "markAllAsReadButton"]
  static values = {
    url: String,
    markAsReadUrl: String,
    markAllAsReadUrl: String
  }

  connect() {
    // Close dropdown when clicking outside
    document.addEventListener("click", this.closeDropdownOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.closeDropdownOutside)
  }

  closeDropdownOutside = (event) => {
    if (!this.element.contains(event.target) && this.isPanelOpen()) {
      this.close()
    }
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    this.isPanelOpen() ? this.close() : this.open()
  }

  toggleDropdown(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.isPanelOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    // Fetch latest notifications when opening dropdown
    this.fetchNotifications()
  }

  close() {
    this.panelTarget.classList.add("hidden")
  }

  isPanelOpen() {
    return !this.panelTarget.classList.contains("hidden")
  }

  fetchNotifications() {
    if (!this.urlValue) return

    fetch(this.urlValue, {
      headers: {
        Accept: "text/html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
      .then(response => response.text())
      .then(html => {
        this.listTarget.innerHTML = html
        this.updateBadgeCount()
      })
      .catch(error => {
        console.error("Error fetching notifications:", error)
      })
  }

  markAsRead(event) {
    event.preventDefault()
    
    const notificationId = event.currentTarget.dataset.notificationId
    const url = `${this.markAsReadUrlValue}/${notificationId}`
    
    fetch(url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": this.getMetaValue("csrf-token"),
        Accept: "application/json, text/vnd.turbo-stream.html",
        "Content-Type": "application/json"
      }
    })
      .then(response => {
        const contentType = response.headers.get("Content-Type") || "";
        if (contentType.includes("application/json")) {
          return response.json();
        } else if (contentType.includes("text/vnd.turbo-stream.html")) {
          // Let Turbo handle the stream response
          return { success: true };
        }
        return { success: false };
      })
      .then(data => {
        if (data.success) {
          // Mark notification as read in UI
          event.currentTarget.classList.remove("unread")
          event.currentTarget.classList.add("read")
          this.updateBadgeCount()
        }
      })
      .catch(error => {
        console.error("Error marking notification as read:", error)
      })
  }

  markAllAsRead(event) {
    event.preventDefault()
    
    fetch(this.markAllAsReadUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": this.getMetaValue("csrf-token"),
        Accept: "application/json, text/vnd.turbo-stream.html",
        "Content-Type": "application/json"
      }
    })
      .then(response => {
        const contentType = response.headers.get("Content-Type") || "";
        if (contentType.includes("application/json")) {
          return response.json();
        } else if (contentType.includes("text/vnd.turbo-stream.html")) {
          // Let Turbo handle the stream response
          return { success: true };
        }
        return { success: false };
      })
      .then(data => {
        if (data.success) {
          // Mark all notifications as read in UI
          this.listTarget.querySelectorAll(".notification-item").forEach(item => {
            item.classList.remove("unread")
            item.classList.add("read")
          })
          this.updateBadgeCount(0)
        }
      })
      .catch(error => {
        console.error("Error marking all notifications as read:", error)
      })
  }

  updateBadgeCount(count) {
    if (count !== undefined) {
      this.badgeTarget.textContent = count
      if (count === 0) {
        this.badgeTarget.classList.add("hidden")
      } else {
        this.badgeTarget.classList.remove("hidden")
      }
      return
    }
    
    // Count unread notifications in the dropdown
    const unreadCount = this.listTarget.querySelectorAll(".notification-item.unread").length
    this.badgeTarget.textContent = unreadCount
    
    if (unreadCount === 0) {
      this.badgeTarget.classList.add("hidden")
      if (this.hasMarkAllAsReadButtonTarget) {
        this.markAllAsReadButtonTarget.classList.add("hidden")
      }
    } else {
      this.badgeTarget.classList.remove("hidden")
      if (this.hasMarkAllAsReadButtonTarget) {
        this.markAllAsReadButtonTarget.classList.remove("hidden")
      }
    }
  }

  getMetaValue(name) {
    const element = document.head.querySelector(`meta[name="${name}"]`)
    return element.getAttribute("content")
  }
}

