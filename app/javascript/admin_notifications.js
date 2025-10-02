/**
 * Global Admin Notification System
 * Provides consistent notification functionality across all admin pages
 */

// Ensure the notifications work properly in all admin pages
document.addEventListener('DOMContentLoaded', function() {
  // Initialize notification container if it doesn't exist
  if (!document.getElementById('admin-notifications')) {
    const container = document.createElement('div');
    container.id = 'admin-notifications';
    container.style.cssText = `
      position: fixed;
      top: 1rem;
      right: 1rem;
      z-index: 10000;
      display: flex;
      flex-direction: column;
      gap: 0.75rem;
      pointer-events: none;
      max-width: 24rem;
    `;
    document.body.appendChild(container);
  }
});

/**
 * Show notification in admin interface
 * @param {string} message - The message to display
 * @param {string} type - Type of notification: 'success', 'error', 'info', 'warning'
 * @returns {HTMLElement} The notification element
 */
function showAdminNotification(message, type = 'info') {
  // Get or create the notification container
  let container = document.getElementById('admin-notifications');
  if (!container) {
    container = document.createElement('div');
    container.id = 'admin-notifications';
    container.style.cssText = `
      position: fixed;
      top: 1rem;
      right: 1rem;
      z-index: 10000;
      display: flex;
      flex-direction: column;
      gap: 0.75rem;
      pointer-events: none;
      max-width: 24rem;
    `;
    document.body.appendChild(container);
  }

  // Create notification element
  const notification = document.createElement('div');
  notification.className = 'admin-notification';
  
  // Notification styles
  notification.style.cssText = `
    padding: 1rem;
    border-radius: 0.5rem;
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
    backdrop-filter: blur(8px);
    pointer-events: auto;
    transform: translateX(100%);
    opacity: 0;
    transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    border: 1px solid rgba(255, 255, 255, 0.1);
    max-width: 100%;
    word-wrap: break-word;
    position: relative;
  `;
  
  // Set colors and content based on type
  let bgColor, textColor, icon, title;
  
  switch(type) {
    case 'success':
      bgColor = 'linear-gradient(135deg, rgba(16, 185, 129, 0.95), rgba(5, 150, 105, 0.95))';
      textColor = 'white';
      icon = 'fa-check-circle';
      title = 'Success';
      break;
    case 'error':
      bgColor = 'linear-gradient(135deg, rgba(239, 68, 68, 0.95), rgba(220, 38, 38, 0.95))';
      textColor = 'white';
      icon = 'fa-exclamation-circle';
      title = 'Error';
      break;
    case 'warning':
      bgColor = 'linear-gradient(135deg, rgba(245, 158, 11, 0.95), rgba(217, 119, 6, 0.95))';
      textColor = 'white';
      icon = 'fa-exclamation-triangle';
      title = 'Warning';
      break;
    default: // info
      bgColor = 'linear-gradient(135deg, rgba(59, 130, 246, 0.95), rgba(29, 78, 216, 0.95))';
      textColor = 'white';
      icon = 'fa-info-circle';
      title = 'Info';
  }
  
  notification.style.background = bgColor;
  notification.style.color = textColor;
  
  // Create notification content
  const contentHTML = (type === 'error' || type === 'warning') ? `
    <div style="display: flex; align-items: flex-start; gap: 0.75rem;">
      <i class="fas ${icon}" style="font-size: 1.25rem; margin-top: 0.125rem; flex-shrink: 0;"></i>
      <div style="flex: 1; min-width: 0;">
        <p style="margin: 0 0 0.25rem 0; font-weight: 600; font-size: 0.875rem;">${title}</p>
        <p style="margin: 0; font-size: 0.8125rem; opacity: 0.95; line-height: 1.4;">${message}</p>
      </div>
      <button class="notification-close" style="background: none; border: none; color: inherit; cursor: pointer; padding: 0.25rem; margin: -0.25rem; border-radius: 0.25rem; opacity: 0.7; transition: opacity 0.2s; flex-shrink: 0;">
        <i class="fas fa-times" style="font-size: 0.875rem;"></i>
      </button>
    </div>
  ` : `
    <div style="display: flex; align-items: center; gap: 0.75rem;">
      <i class="fas ${icon}" style="font-size: 1.25rem; flex-shrink: 0;"></i>
      <div style="flex: 1; min-width: 0;">
        <p style="margin: 0; font-weight: 500; font-size: 0.875rem; line-height: 1.4;">${message}</p>
      </div>
      <button class="notification-close" style="background: none; border: none; color: inherit; cursor: pointer; padding: 0.25rem; margin: -0.25rem; border-radius: 0.25rem; opacity: 0.7; transition: opacity 0.2s; flex-shrink: 0;">
        <i class="fas fa-times" style="font-size: 0.875rem;"></i>
      </button>
    </div>
  `;
  
  notification.innerHTML = contentHTML;
  
  // Add close button functionality
  const closeButton = notification.querySelector('.notification-close');
  closeButton.addEventListener('click', () => removeAdminNotification(notification));
  closeButton.addEventListener('mouseenter', () => closeButton.style.opacity = '1');
  closeButton.addEventListener('mouseleave', () => closeButton.style.opacity = '0.7');
  
  // Add to container
  container.appendChild(notification);
  
  // Animate in
  requestAnimationFrame(() => {
    notification.style.transform = 'translateX(0)';
    notification.style.opacity = '1';
  });
  
  // Auto remove
  const autoRemoveTime = (type === 'error' || type === 'warning') ? 8000 : 5000;
  setTimeout(() => {
    removeAdminNotification(notification);
  }, autoRemoveTime);
  
  return notification;
}

/**
 * Remove notification with animation
 * @param {HTMLElement} notification - The notification element to remove
 */
function removeAdminNotification(notification) {
  if (!notification || !notification.parentElement) return;
  
  notification.style.transform = 'translateX(100%)';
  notification.style.opacity = '0';
  
  setTimeout(() => {
    if (notification.parentElement) {
      notification.parentElement.removeChild(notification);
    }
  }, 300);
}

/**
 * Clear all notifications
 */
function clearAllAdminNotifications() {
  const container = document.getElementById('admin-notifications');
  if (container) {
    const notifications = container.querySelectorAll('.admin-notification');
    notifications.forEach(notification => {
      removeAdminNotification(notification);
    });
  }
}

// Backward compatibility - alias the function
window.showNotification = showAdminNotification;