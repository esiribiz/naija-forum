// Admin Sidebar JavaScript
// Handles mobile sidebar toggle functionality and responsive behavior

document.addEventListener('DOMContentLoaded', function() {
  // Mobile sidebar toggle
  const sidebarToggle = document.getElementById('sidebar-toggle');
  const mobileSidebar = document.getElementById('mobile-sidebar');
  const mobileSidebarClose = document.getElementById('mobile-sidebar-close');
  const mobileSidebarOverlay = document.getElementById('mobile-sidebar-overlay');
  const desktopSidebar = document.getElementById('admin-sidebar');
  
  // Show mobile sidebar
  function showMobileSidebar() {
    if (mobileSidebar) {
      mobileSidebar.style.display = 'flex';
      document.body.style.overflow = 'hidden';
    }
  }
  
  // Hide mobile sidebar
  function hideMobileSidebar() {
    if (mobileSidebar) {
      mobileSidebar.style.display = 'none';
      document.body.style.overflow = '';
    }
  }
  
  // Handle mobile sidebar toggle for the main desktop sidebar
  function toggleMobileSidebar() {
    if (desktopSidebar) {
      desktopSidebar.classList.toggle('mobile-open');
    }
  }
  
  // Main sidebar toggle event listener
  if (sidebarToggle) {
    sidebarToggle.addEventListener('click', function(e) {
      e.preventDefault();
      // Always use the main sidebar with CSS toggle
      toggleMobileSidebar();
    });
  }
  
  // Keep overlay sidebar functionality as fallback
  if (mobileSidebarClose) {
    mobileSidebarClose.addEventListener('click', hideMobileSidebar);
  }
  
  if (mobileSidebarOverlay) {
    mobileSidebarOverlay.addEventListener('click', hideMobileSidebar);
  }
  
  // Handle window resize - responsive behavior
  window.addEventListener('resize', function() {
    if (window.innerWidth >= 768) {
      hideMobileSidebar();
      // Remove mobile-open class on desktop
      if (desktopSidebar) {
        desktopSidebar.classList.remove('mobile-open');
      }
    }
  });
  
  // Initialize sidebar state
  if (desktopSidebar) {
    if (window.innerWidth < 768) {
      desktopSidebar.classList.remove('mobile-open');
    }
  }
  
  // Auto-hide flash messages
  const flashMessages = document.querySelectorAll('.flash-message');
  flashMessages.forEach(function(message) {
    setTimeout(function() {
      message.style.opacity = '0';
      message.style.transform = 'translateX(100%)';
      setTimeout(function() {
        message.remove();
      }, 300);
    }, 5000);
  });
});