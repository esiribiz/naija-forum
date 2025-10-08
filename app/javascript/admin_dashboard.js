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
          borderColor: '#10b981',
          backgroundColor: 'rgba(16, 185, 129, 0.1)',
          borderWidth: 3,
          fill: true,
          tension: 0.4,
          pointBackgroundColor: '#10b981',
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
          backgroundColor: 'rgba(16, 185, 129, 0.8)',
          borderColor: '#10b981',
          borderWidth: 1,
          borderRadius: 4,
        }, {
          label: 'Comments',
          data: commentActivityData,
          backgroundColor: 'rgba(245, 158, 11, 0.8)',
          borderColor: '#f59e0b',
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
});