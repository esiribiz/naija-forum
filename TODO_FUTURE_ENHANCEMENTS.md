# Future Enhancement TODOs

## Posts View Toggle Feature
**Priority**: Medium  
**Status**: Deferred  
**Estimated Effort**: 2-3 hours  

### Description
Implement a toggle feature that allows users to switch between grid and list views on the posts index page.

### Implementation Details
- **Files Ready**: 
  - `app/assets/stylesheets/components/post_view_toggle.css` (commented out, ready to use)
  - `app/javascript/post_view_toggle.js` (commented out, ready to use)
  
### Features to Implement
1. **Toggle Buttons**: Grid and list view icons in the posts header
2. **Grid View**: Default responsive card layout (1-2 columns)
3. **List View**: Compact horizontal layout with:
   - User avatar as left sidebar (180px width)
   - Main content area with title and excerpt
   - Images hidden for cleaner appearance
   - Consistent post height (120-200px)
4. **Responsive Design**: Mobile-friendly adaptations
5. **Smooth Transitions**: CSS transitions between view changes
6. **User Preference**: LocalStorage persistence of selected view

### Technical Notes
- HTML structure has been simplified and is ready for toggle implementation
- CSS uses flexbox for list view and CSS Grid for grid view
- JavaScript handles smooth transitions with opacity changes
- All classes and IDs are properly structured

### To Re-enable
1. Uncomment the CSS and JavaScript files
2. Add `import "post_view_toggle"` to `app/javascript/application.js`
3. Add toggle buttons back to `app/views/posts/index.html.erb`
4. Restore toggle-specific classes to the posts container and cards

### Why Deferred
The feature was working but added UI complexity that wasn't immediately needed. The implementation is solid and can be easily restored when the user interface priorities change.

---

## Other Future Enhancements
- [ ] Advanced search and filtering for posts
- [ ] Post categories with color-coded tags
- [ ] Real-time notifications for new comments
- [ ] Dark mode theme toggle
- [ ] Post bookmarking/favorites functionality
- [ ] User reputation system based on post engagement