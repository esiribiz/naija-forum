// Admin Dashboard Professional Animations and Interactions

document.addEventListener('DOMContentLoaded', function() {
  
  // Real-time Clock Update
  function updateClock() {
    const clockElement = document.getElementById('current-time');
    if (clockElement) {
      const now = new Date();
      const options = {
        hour: 'numeric',
        minute: '2-digit',
        hour12: true,
        month: 'long',
        day: 'numeric',
        year: 'numeric'
      };
      clockElement.textContent = now.toLocaleString('en-US', options);
    }
  }
  
  // Update clock every minute
  updateClock(); // Initial update
  setInterval(updateClock, 60000); // Update every minute
  
  // Professional Loading Animation
  function showLoading(element) {
    if (!element) return;
    
    const loader = document.createElement('div');
    loader.className = 'admin-loading';
    loader.innerHTML = '<div class="admin-loading"></div>';
    
    element.style.position = 'relative';
    element.appendChild(loader);
    
    return loader;
  }
  
  function hideLoading(loader) {
    if (loader && loader.parentNode) {
      loader.parentNode.removeChild(loader);
    }
  }

  // Smooth Card Animations
  function initCardAnimations() {
    const cards = document.querySelectorAll('.admin-stat-card, .admin-card');
    
    cards.forEach((card, index) => {
      // Stagger animation
      card.style.opacity = '0';
      card.style.transform = 'translateY(20px)';
      
      setTimeout(() => {
        card.style.transition = 'opacity 0.6s ease-out, transform 0.6s ease-out';
        card.style.opacity = '1';
        card.style.transform = 'translateY(0)';
      }, index * 100);
    });
  }

  // Enhanced Table Row Animations
  function initTableAnimations() {
    const tableRows = document.querySelectorAll('.admin-table tbody tr');
    
    tableRows.forEach((row, index) => {
      row.style.opacity = '0';
      row.style.transform = 'translateX(-10px)';
      
      setTimeout(() => {
        row.style.transition = 'opacity 0.4s ease-out, transform 0.4s ease-out';
        row.style.opacity = '1';
        row.style.transform = 'translateX(0)';
      }, index * 50);
    });
  }

  // Navigation Active State Animation
  function initNavigationAnimations() {
    const navItems = document.querySelectorAll('.admin-sidebar-nav-item');
    
    navItems.forEach(item => {
      item.addEventListener('mouseenter', function() {
        this.style.transform = 'translateX(4px)';
      });
      
      item.addEventListener('mouseleave', function() {
        if (!this.classList.contains('active')) {
          this.style.transform = 'translateX(0)';
        }
      });
    });
  }

  // Stat Counter Animation
  function animateCounters() {
    const counters = document.querySelectorAll('.admin-stat-number');
    
    counters.forEach(counter => {
      const target = parseInt(counter.textContent.replace(/,/g, ''));
      const increment = target / 60; // Animation duration in frames
      let current = 0;
      
      const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
          counter.textContent = target.toLocaleString();
          clearInterval(timer);
        } else {
          counter.textContent = Math.floor(current).toLocaleString();
        }
      }, 16); // ~60fps
    });
  }

  // Interactive Button Effects
  function initButtonEffects() {
    const buttons = document.querySelectorAll('.admin-btn');
    
    buttons.forEach(button => {
      button.addEventListener('click', function(e) {
        // Ripple effect
        const ripple = document.createElement('span');
        const rect = this.getBoundingClientRect();
        const size = Math.max(rect.width, rect.height);
        const x = e.clientX - rect.left - size / 2;
        const y = e.clientY - rect.top - size / 2;
        
        ripple.style.position = 'absolute';
        ripple.style.width = ripple.style.height = size + 'px';
        ripple.style.left = x + 'px';
        ripple.style.top = y + 'px';
        ripple.style.background = 'rgba(255, 255, 255, 0.3)';
        ripple.style.borderRadius = '50%';
        ripple.style.transform = 'scale(0)';
        ripple.style.animation = 'admin-ripple 0.6s linear';
        ripple.style.pointerEvents = 'none';
        
        this.appendChild(ripple);
        
        setTimeout(() => {
          ripple.remove();
        }, 600);
      });
    });
  }

  // Badge Hover Effects
  function initBadgeEffects() {
    const badges = document.querySelectorAll('.admin-badge');
    
    badges.forEach(badge => {
      badge.addEventListener('mouseenter', function() {
        this.style.transform = 'scale(1.05)';
        this.style.boxShadow = '0 4px 8px rgba(0, 0, 0, 0.1)';
      });
      
      badge.addEventListener('mouseleave', function() {
        this.style.transform = 'scale(1)';
        this.style.boxShadow = 'none';
      });
    });
  }

  // Form Enhancement
  function initFormEnhancements() {
    const inputs = document.querySelectorAll('.admin-form-input');
    
    inputs.forEach(input => {
      // Floating label effect
      const label = input.previousElementSibling;
      
      if (label && label.classList.contains('admin-form-label')) {
        input.addEventListener('focus', function() {
          label.style.transform = 'translateY(-20px) scale(0.85)';
          label.style.color = 'var(--admin-secondary)';
        });
        
        input.addEventListener('blur', function() {
          if (!this.value) {
            label.style.transform = 'translateY(0) scale(1)';
            label.style.color = 'var(--admin-gray-600)';
          }
        });
        
        // Check if input has value on load
        if (input.value) {
          label.style.transform = 'translateY(-20px) scale(0.85)';
        }
      }
    });
  }

  // Notification Toast Animation
  function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `admin-toast admin-toast-${type}`;
    toast.innerHTML = `
      <div class="flex items-center">
        <div class="flex-shrink-0">
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
        </div>
        <div class="ml-3">
          <p class="text-sm font-medium">${message}</p>
        </div>
      </div>
    `;
    
    toast.style.position = 'fixed';
    toast.style.top = '20px';
    toast.style.right = '20px';
    toast.style.zIndex = '9999';
    toast.style.transform = 'translateX(100%)';
    toast.style.transition = 'transform 0.3s ease-out';
    
    document.body.appendChild(toast);
    
    setTimeout(() => {
      toast.style.transform = 'translateX(0)';
    }, 100);
    
    setTimeout(() => {
      toast.style.transform = 'translateX(100%)';
      setTimeout(() => {
        document.body.removeChild(toast);
      }, 300);
    }, 3000);
  }

  // Progressive Enhancement for Stats
  function initProgressBars() {
    const progressBars = document.querySelectorAll('[data-progress]');
    
    progressBars.forEach(bar => {
      const progress = bar.getAttribute('data-progress');
      const fill = bar.querySelector('.progress-fill');
      
      if (fill) {
        setTimeout(() => {
          fill.style.width = progress + '%';
        }, 500);
      }
    });
  }

  // Smooth Scrolling for Anchor Links
  function initSmoothScrolling() {
    const links = document.querySelectorAll('a[href^="#"]');
    
    links.forEach(link => {
      link.addEventListener('click', function(e) {
        e.preventDefault();
        
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
          target.scrollIntoView({
            behavior: 'smooth',
            block: 'start'
          });
        }
      });
    });
  }

  // Auto-save Indication
  function initAutoSave() {
    const forms = document.querySelectorAll('form[data-autosave]');
    
    forms.forEach(form => {
      const inputs = form.querySelectorAll('input, textarea, select');
      let saveTimeout;
      
      inputs.forEach(input => {
        input.addEventListener('input', function() {
          clearTimeout(saveTimeout);
          
          // Show saving indicator
          const indicator = document.createElement('div');
          indicator.className = 'auto-save-indicator';
          indicator.textContent = 'Saving...';
          
          this.parentNode.appendChild(indicator);
          
          saveTimeout = setTimeout(() => {
            // Simulate save
            indicator.textContent = 'Saved';
            indicator.style.color = 'var(--admin-success)';
            
            setTimeout(() => {
              indicator.remove();
            }, 2000);
          }, 1000);
        });
      });
    });
  }

  // Initialize all animations
  function init() {
    initCardAnimations();
    initTableAnimations();
    initNavigationAnimations();
    initButtonEffects();
    initBadgeEffects();
    initFormEnhancements();
    initProgressBars();
    initSmoothScrolling();
    initAutoSave();
    
    // Animate counters after a short delay
    setTimeout(animateCounters, 800);
  }

  // Run initialization
  init();

  // Export functions for use in other scripts
  window.AdminUI = {
    showLoading,
    hideLoading,
    showToast,
    animateCounters
  };
});

// CSS for toast notifications and ripple effect
const adminStyles = document.createElement('style');
adminStyles.textContent = `
  @keyframes admin-ripple {
    to {
      transform: scale(4);
      opacity: 0;
    }
  }

  .admin-toast {
    padding: 1rem 1.5rem;
    border-radius: 0.75rem;
    box-shadow: var(--admin-shadow-lg);
    background: white;
    border: 1px solid var(--admin-gray-200);
    min-width: 300px;
  }

  .admin-toast-success {
    border-left: 4px solid var(--admin-success);
    color: var(--admin-success);
  }

  .admin-toast-error {
    border-left: 4px solid var(--admin-error);
    color: var(--admin-error);
  }

  .admin-toast-warning {
    border-left: 4px solid var(--admin-warning);
    color: var(--admin-warning);
  }

  .admin-toast-info {
    border-left: 4px solid var(--admin-info);
    color: var(--admin-info);
  }

  .progress-fill {
    height: 100%;
    background: linear-gradient(90deg, var(--admin-secondary), var(--admin-accent));
    border-radius: inherit;
    transition: width 1s ease-out;
    width: 0;
  }

  .auto-save-indicator {
    position: absolute;
    top: -1.5rem;
    right: 0;
    font-size: 0.75rem;
    color: var(--admin-gray-500);
    transition: all 0.3s ease;
  }
`;

document.head.appendChild(adminStyles);