// Admin Dashboard Charts JavaScript
// Handles Chart.js initialization and dashboard animations

document.addEventListener('DOMContentLoaded', function() {
  // User Growth Chart
  const userGrowthCtx = document.getElementById('userGrowthChart');
  if (userGrowthCtx) {
    // Get data from data attributes or global variables
    const userGrowthLabels = window.userGrowthLabels || [];
    const userGrowthData = window.userGrowthData || [];
    
    const userGrowthChart = new Chart(userGrowthCtx, {
      type: 'line',
      data: {
        labels: userGrowthLabels,
        datasets: [{
          label: 'New Users',
          data: userGrowthData,
          borderColor: '#2563eb',
          backgroundColor: 'rgba(37, 99, 235, 0.1)',
          borderWidth: 3,
          fill: true,
          tension: 0.4,
          pointBackgroundColor: '#2563eb',
          pointBorderColor: '#ffffff',
          pointBorderWidth: 2,
          pointRadius: 6,
          pointHoverRadius: 8
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            },
            ticks: {
              color: '#6b7280'
            }
          },
          x: {
            grid: {
              display: false
            },
            ticks: {
              color: '#6b7280'
            }
          }
        }
      }
    });
  }

  // Content Activity Chart
  const contentActivityCtx = document.getElementById('contentActivityChart');
  if (contentActivityCtx) {
    // Get data from data attributes or global variables
    const postActivityLabels = window.postActivityLabels || [];
    const postActivityData = window.postActivityData || [];
    const commentActivityData = window.commentActivityData || [];
    
    const contentActivityChart = new Chart(contentActivityCtx, {
      type: 'bar',
      data: {
        labels: postActivityLabels,
        datasets: [{
          label: 'Posts',
          data: postActivityData,
          backgroundColor: 'rgba(34, 197, 94, 0.8)',
          borderColor: '#22c55e',
          borderWidth: 1,
          borderRadius: 4,
        }, {
          label: 'Comments',
          data: commentActivityData,
          backgroundColor: 'rgba(234, 179, 8, 0.8)',
          borderColor: '#eab308',
          borderWidth: 1,
          borderRadius: 4,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'top',
            labels: {
              usePointStyle: true,
              pointStyle: 'circle',
              color: '#6b7280'
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            },
            ticks: {
              color: '#6b7280'
            }
          },
          x: {
            grid: {
              display: false
            },
            ticks: {
              color: '#6b7280'
            }
          }
        }
      }
    });
  }

  // Animate stat cards on page load
  const statCards = document.querySelectorAll('.stat-card');
  statCards.forEach((card, index) => {
    setTimeout(() => {
      card.style.opacity = '0';
      card.style.transform = 'translateY(20px)';
      card.style.transition = 'all 0.6s cubic-bezier(0.4, 0, 0.2, 1)';
      
      setTimeout(() => {
        card.style.opacity = '1';
        card.style.transform = 'translateY(0)';
      }, 100);
    }, index * 150);
  });
  
  // Activity filter functionality
  window.filterActivityData = function(period) {
    // Update button states
    const filterButtons = document.querySelectorAll('[onclick*="filterActivityData"]');
    filterButtons.forEach(btn => {
      btn.classList.remove('bg-gradient-to-r', 'from-green-500', 'to-emerald-600', 'text-white', 'shadow-lg', 'hover:shadow-green-500/25', 'active');
      btn.classList.add('text-slate-600', 'bg-white/80', 'border', 'border-slate-200');
    });
    
    // Activate clicked button
    event.target.classList.remove('text-slate-600', 'bg-white/80', 'border', 'border-slate-200');
    event.target.classList.add('bg-gradient-to-r', 'from-green-500', 'to-emerald-600', 'text-white', 'shadow-lg', 'hover:shadow-green-500/25', 'active');
    
    // Here you could implement actual data filtering logic
    console.log('Filtering activity data for period:', period);
    
    // Show a subtle notification
    showNotification(`Activity view updated to show ${period === '24h' ? 'last 24 hours' : 'last week'}`, 'info');
  };
  
  // Simple notification system
  window.showNotification = function(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `fixed top-4 right-4 z-50 p-4 rounded-lg shadow-lg transition-all duration-300 transform translate-x-full opacity-0 ${type === 'info' ? 'bg-blue-50 border border-blue-200 text-blue-800' : 'bg-green-50 border border-green-200 text-green-800'}`;
    notification.innerHTML = `
      <div class="flex items-center">
        <svg class="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path>
        </svg>
        <span class="text-sm font-medium">${message}</span>
      </div>
    `;
    
    document.body.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
      notification.classList.remove('translate-x-full', 'opacity-0');
    }, 100);
    
    // Auto remove after 3 seconds
    setTimeout(() => {
      notification.classList.add('translate-x-full', 'opacity-0');
      setTimeout(() => {
        document.body.removeChild(notification);
      }, 300);
    }, 3000);
  };
});
