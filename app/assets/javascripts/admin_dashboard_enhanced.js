// Enhanced Admin Dashboard JavaScript Module
// Provides chart interactivity, real-time updates, and enhanced UX features

class AdminDashboard {
  constructor() {
    this.userGrowthChart = null;
    this.contentActivityChart = null;
    this.refreshInterval = null;
    this.websocket = null;
    
    this.init();
  }
  
  init() {
    this.initCharts();
    this.setupRealTimeUpdates();
    this.initNotificationSystem();
    this.setupKeyboardNavigation();
    this.initTooltips();
  }
  
  // Initialize interactive charts
  initCharts() {
    if (typeof Chart === 'undefined') {
      console.warn('Chart.js not loaded. Charts will not be interactive.');
      return;
    }
    
    this.initUserGrowthChart();
    this.initContentActivityChart();
  }
  
  initUserGrowthChart() {
    const ctx = document.getElementById('userGrowthChart');
    if (!ctx) return;
    
    const gradient = ctx.getContext('2d').createLinearGradient(0, 0, 0, 200);
    gradient.addColorStop(0, 'rgba(59, 130, 246, 0.3)');
    gradient.addColorStop(1, 'rgba(59, 130, 246, 0.0)');
    
    this.userGrowthChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: window.userGrowthLabels || [],
        datasets: [{
          label: 'User Growth',
          data: window.userGrowthData || [],
          borderColor: 'rgb(59, 130, 246)',
          backgroundColor: gradient,
          borderWidth: 3,
          fill: true,
          tension: 0.4,
          pointBackgroundColor: 'rgb(59, 130, 246)',
          pointBorderColor: '#ffffff',
          pointBorderWidth: 2,
          pointRadius: 6,
          pointHoverRadius: 8
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          intersect: false,
          mode: 'index'
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: 'rgba(17, 24, 39, 0.95)',
            titleColor: '#ffffff',
            bodyColor: '#ffffff',
            borderColor: 'rgb(59, 130, 246)',
            borderWidth: 1,
            cornerRadius: 8,
            displayColors: false,
            callbacks: {
              title: function(context) {
                return 'Users on ' + context[0].label;
              },
              label: function(context) {
                return `${context.parsed.y} new users`;
              }
            }
          }
        },
        scales: {
          x: {
            display: true,
            grid: {
              display: false
            },
            ticks: {
              color: '#6B7280',
              font: {
                size: 12
              }
            }
          },
          y: {
            display: true,
            grid: {
              color: 'rgba(156, 163, 175, 0.1)'
            },
            ticks: {
              color: '#6B7280',
              font: {
                size: 12
              }
            }
          }
        },
        onHover: (event, activeElements) => {
          event.native.target.style.cursor = activeElements.length > 0 ? 'pointer' : 'default';
        },
        onClick: (event, activeElements) => {
          if (activeElements.length > 0) {
            const dataIndex = activeElements[0].index;
            const date = window.userGrowthLabels[dataIndex];
            this.showDetailedUserData(date);
          }
        }
      }
    });
  }
  
  initContentActivityChart() {
    const ctx = document.getElementById('contentActivityChart');
    if (!ctx) return;
    
    this.contentActivityChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: window.postActivityLabels || [],
        datasets: [
          {
            label: 'Posts',
            data: window.postActivityData || [],
            backgroundColor: 'rgba(34, 197, 94, 0.7)',
            borderColor: 'rgb(34, 197, 94)',
            borderWidth: 2,
            borderRadius: 6,
            borderSkipped: false
          },
          {
            label: 'Comments',
            data: window.commentActivityData || [],
            backgroundColor: 'rgba(251, 191, 36, 0.7)',
            borderColor: 'rgb(251, 191, 36)',
            borderWidth: 2,
            borderRadius: 6,
            borderSkipped: false
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          intersect: false,
          mode: 'index'
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            backgroundColor: 'rgba(17, 24, 39, 0.95)',
            titleColor: '#ffffff',
            bodyColor: '#ffffff',
            borderColor: 'rgb(34, 197, 94)',
            borderWidth: 1,
            cornerRadius: 8
          }
        },
        scales: {
          x: {
            display: true,
            grid: {
              display: false
            },
            ticks: {
              color: '#6B7280',
              font: {
                size: 12
              }
            }
          },
          y: {
            display: true,
            grid: {
              color: 'rgba(156, 163, 175, 0.1)'
            },
            ticks: {
              color: '#6B7280',
              font: {
                size: 12
              }
            }
          }
        },
        onHover: (event, activeElements) => {
          event.native.target.style.cursor = activeElements.length > 0 ? 'pointer' : 'default';
        }
      }
    });
  }
  
  // Setup real-time updates
  setupRealTimeUpdates() {
    // Auto-refresh dashboard data every 5 minutes
    this.refreshInterval = setInterval(() => {
      this.refreshDashboardData();
    }, 300000); // 5 minutes
    
    // Setup WebSocket connection for real-time notifications (if available)
    this.initWebSocket();
  }
  
  initWebSocket() {
    // This would connect to your WebSocket endpoint for real-time updates
    // Implementation depends on your backend setup (ActionCable for Rails)
    if (typeof App !== 'undefined' && App.cable) {
      this.websocket = App.cable.subscriptions.create("AdminNotificationChannel", {
        received: (data) => {
          this.handleRealTimeNotification(data);
        }
      });
    }
  }
  
  refreshDashboardData() {
    // Fetch updated statistics and refresh charts
    fetch('/admin/dashboard/refresh', {
      method: 'GET',
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'Content-Type': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      this.updateStatistics(data.stats);
      this.updateChartData(data.chartData);
      this.updateRecentActivity(data.recentActivity);
      this.showUpdateIndicator();
    })
    .catch(error => {
      console.error('Failed to refresh dashboard data:', error);
    });
  }
  
  updateStatistics(stats) {
    // Update the statistic cards with new data
    Object.keys(stats).forEach(key => {
      const element = document.querySelector(`[data-stat="${key}"]`);
      if (element) {
        const newValue = stats[key];
        this.animateCounterUpdate(element, newValue);
      }
    });
  }
  
  animateCounterUpdate(element, newValue) {
    const currentValue = parseInt(element.textContent.replace(/,/g, '')) || 0;
    const duration = 1000; // 1 second
    const steps = 60;
    const increment = (newValue - currentValue) / steps;
    
    let current = currentValue;
    let step = 0;
    
    const timer = setInterval(() => {
      step++;
      current += increment;
      
      if (step >= steps) {
        current = newValue;
        clearInterval(timer);
      }
      
      element.textContent = Math.round(current).toLocaleString();
    }, duration / steps);
  }
  
  updateChartData(chartData) {
    if (this.userGrowthChart && chartData.userGrowth) {
      this.userGrowthChart.data.labels = chartData.userGrowth.labels;
      this.userGrowthChart.data.datasets[0].data = chartData.userGrowth.data;
      this.userGrowthChart.update('smooth');
    }
    
    if (this.contentActivityChart && chartData.contentActivity) {
      this.contentActivityChart.data.labels = chartData.contentActivity.labels;
      this.contentActivityChart.data.datasets[0].data = chartData.contentActivity.posts;
      this.contentActivityChart.data.datasets[1].data = chartData.contentActivity.comments;
      this.contentActivityChart.update('smooth');
    }
  }
  
  showUpdateIndicator() {
    const indicator = document.createElement('div');
    indicator.className = 'fixed top-4 right-4 bg-green-500 text-white px-4 py-2 rounded-lg shadow-lg z-50';
    indicator.innerHTML = '<i class="fas fa-check mr-2"></i>Dashboard updated';
    document.body.appendChild(indicator);
    
    setTimeout(() => {
      indicator.style.opacity = '0';
      indicator.style.transform = 'translateX(100%)';
      setTimeout(() => indicator.remove(), 300);
    }, 2000);
  }
  
  // Enhanced notification system
  initNotificationSystem() {
    this.setupNotificationPermissions();
  }
  
  setupNotificationPermissions() {
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission();
    }
  }
  
  handleRealTimeNotification(data) {
    // Add notification to the dashboard
    this.addNotificationToUI(data);
    
    // Show browser notification if permitted
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification(data.title, {
        body: data.message,
        icon: '/favicon.ico',
        tag: data.type
      });
    }
    
    // Update relevant statistics
    this.updateStatisticsFromNotification(data);
  }
  
  addNotificationToUI(notification) {
    const container = document.getElementById('notification-container');
    if (!container) return;
    
    const notificationElement = this.createNotificationElement(notification);
    container.insertBefore(notificationElement, container.firstChild);
    
    // Animate in
    setTimeout(() => {
      notificationElement.style.opacity = '1';
      notificationElement.style.transform = 'translateX(0)';
    }, 100);
  }
  
  createNotificationElement(notification) {
    const element = document.createElement('div');
    element.className = 'notification-item bg-gradient-to-r from-blue-50 to-blue-100/50 dark:from-blue-900/20 dark:to-blue-900/40 border border-blue-200/50 dark:border-blue-700/30 rounded-lg p-3 flex items-center justify-between group hover:shadow-md transition-all duration-200';
    element.style.opacity = '0';
    element.style.transform = 'translateX(-100%)';
    
    element.innerHTML = `
      <div class="flex items-center space-x-3">
        <div class="p-1.5 bg-blue-100 dark:bg-blue-900/50 rounded-lg">
          <i class="fas ${notification.icon} text-blue-600 dark:text-blue-400 text-xs"></i>
        </div>
        <div>
          <p class="text-xs font-semibold text-blue-800 dark:text-blue-300">${notification.title}</p>
          <p class="text-xs text-blue-600 dark:text-blue-400">${notification.message}</p>
        </div>
      </div>
      <button class="opacity-0 group-hover:opacity-100 text-blue-500 hover:text-blue-700 transition-opacity" onclick="dismissNotification(this)">
        <i class="fas fa-times text-xs"></i>
      </button>
    `;
    
    return element;
  }
  
  // Keyboard navigation support
  setupKeyboardNavigation() {
    document.addEventListener('keydown', (event) => {
      if (event.altKey) {
        switch (event.code) {
          case 'KeyN':
            event.preventDefault();
            this.focusNotifications();
            break;
          case 'KeyS':
            event.preventDefault();
            this.focusStatistics();
            break;
          case 'KeyU':
            event.preventDefault();
            this.focusUsers();
            break;
          case 'KeyP':
            event.preventDefault();
            this.focusPosts();
            break;
        }
      }
    });
  }
  
  focusNotifications() {
    const notifications = document.querySelector('#notification-container');
    if (notifications) notifications.focus();
  }
  
  focusStatistics() {
    const stats = document.querySelector('.grid.grid-cols-2.sm\\:grid-cols-2.md\\:grid-cols-3.lg\\:grid-cols-4');
    if (stats) stats.firstElementChild.focus();
  }
  
  focusUsers() {
    const users = document.querySelector('#recent-users-container');
    if (users) users.firstElementChild.focus();
  }
  
  focusPosts() {
    const posts = document.querySelector('#recent-posts-container');
    if (posts) posts.firstElementChild.focus();
  }
  
  // Enhanced tooltips
  initTooltips() {
    const tooltipTriggers = document.querySelectorAll('[data-tooltip]');
    
    tooltipTriggers.forEach(trigger => {
      let tooltip = null;
      
      trigger.addEventListener('mouseenter', () => {
        const text = trigger.getAttribute('data-tooltip');
        tooltip = this.createTooltip(text);
        document.body.appendChild(tooltip);
        this.positionTooltip(tooltip, trigger);
      });
      
      trigger.addEventListener('mouseleave', () => {
        if (tooltip) {
          tooltip.remove();
          tooltip = null;
        }
      });
    });
  }
  
  createTooltip(text) {
    const tooltip = document.createElement('div');
    tooltip.className = 'absolute bg-gray-900 text-white text-xs px-3 py-2 rounded-lg shadow-lg z-50 pointer-events-none';
    tooltip.textContent = text;
    return tooltip;
  }
  
  positionTooltip(tooltip, trigger) {
    const rect = trigger.getBoundingClientRect();
    const tooltipRect = tooltip.getBoundingClientRect();
    
    tooltip.style.left = `${rect.left + (rect.width / 2) - (tooltipRect.width / 2)}px`;
    tooltip.style.top = `${rect.top - tooltipRect.height - 8}px`;
  }
  
  showDetailedUserData(date) {
    // Show modal or navigate to detailed view
    console.log(`Showing detailed user data for ${date}`);
    // Implementation would depend on your routing and modal system
  }
  
  // Cleanup
  destroy() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
    }
    
    if (this.websocket) {
      this.websocket.unsubscribe();
    }
  }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  window.adminDashboard = new AdminDashboard();
});

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  if (window.adminDashboard) {
    window.adminDashboard.destroy();
  }
});