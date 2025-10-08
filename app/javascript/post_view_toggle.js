/* 
 * POST VIEW TOGGLE FUNCTIONALITY - DISABLED FOR NOW
 * TODO: Re-enable when ready to implement posts grid/list toggle functionality
 */
/*
// Post View Toggle Functionality
document.addEventListener('DOMContentLoaded', function() {
  const postsContainer = document.getElementById('posts-container');
  const gridViewBtn = document.getElementById('grid-view-btn');
  const listViewBtn = document.getElementById('list-view-btn');
  
  if (!postsContainer || !gridViewBtn || !listViewBtn) {
    return; // Exit if elements don't exist on this page
  }
  
  // Load saved view preference from localStorage
  const savedView = localStorage.getItem('postsViewPreference') || 'grid';
  setView(savedView);
  
  // Add click event listeners
  gridViewBtn.addEventListener('click', function() {
    setView('grid');
    localStorage.setItem('postsViewPreference', 'grid');
  });
  
  listViewBtn.addEventListener('click', function() {
    setView('list');
    localStorage.setItem('postsViewPreference', 'list');
  });
  
  function setView(viewType) {
    // Add transitioning class for smooth effect
    postsContainer.classList.add('transitioning');
    
    // Remove existing classes
    postsContainer.classList.remove('posts-grid', 'posts-list');
    gridViewBtn.classList.remove('active');
    listViewBtn.classList.remove('active');
    
    // Small delay for transition effect
    setTimeout(() => {
      // Add appropriate classes
      if (viewType === 'list') {
        postsContainer.classList.add('posts-list');
        listViewBtn.classList.add('active');
        
        // Remove grid classes from container
        postsContainer.classList.remove('grid', 'md:grid-cols-1', 'lg:grid-cols-2', 'gap-6');
      } else {
        postsContainer.classList.add('posts-grid');
        gridViewBtn.classList.add('active');
        
        // Add grid classes back to container if they were removed
        if (!postsContainer.classList.contains('grid')) {
          postsContainer.classList.add('grid', 'gap-6');
        }
      }
      
      // Remove transitioning class after layout change
      setTimeout(() => {
        postsContainer.classList.remove('transitioning');
      }, 100);
    }, 200);
  }
  
  // Handle window resize for responsive behavior
  let resizeTimer;
  window.addEventListener('resize', function() {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(function() {
      // Re-apply current view to ensure proper responsive behavior
      const currentView = postsContainer.classList.contains('posts-list') ? 'list' : 'grid';
      setView(currentView);
    }, 250);
  });
});
*/
