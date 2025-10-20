import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "results"]
  static values = { 
    category: String,
    minLength: { type: Number, default: 2 },
    debounceDelay: { type: Number, default: 300 }
  }

  connect() {
    this.searchTimeout = null
    this.selectedIndex = -1
    
    // Hide dropdown when clicking outside
    document.addEventListener('click', this.handleOutsideClick.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.handleOutsideClick.bind(this))
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
  }

  search() {
    const query = this.inputTarget.value.trim()
    
    // Clear previous timeout
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
    
    // Hide dropdown if query is too short
    if (query.length < this.minLengthValue) {
      this.hideDropdown()
      return
    }
    
    // Debounce the search
    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, this.debounceDelayValue)
  }

  async performSearch(query) {
    try {
      const url = new URL('/tags/suggestions', window.location.origin)
      url.searchParams.append('q', query)
      if (this.categoryValue) {
        url.searchParams.append('category', this.categoryValue)
      }
      
      const response = await fetch(url.toString(), {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (!response.ok) throw new Error('Search failed')
      
      const tags = await response.json()
      this.displayResults(tags, query)
    } catch (error) {
      console.error('Search error:', error)
      this.hideDropdown()
    }
  }

  displayResults(tagsByCategory, query) {
    if (!tagsByCategory || Object.keys(tagsByCategory).length === 0) {
      this.showNoResults(query)
      return
    }

    let html = ''
    
    // Group results by category
    Object.entries(tagsByCategory).forEach(([category, tags]) => {
      if (tags.length === 0) return
      
      // Category header
      html += `
        <div class="px-4 py-2 text-xs font-semibold text-gray-500 uppercase tracking-wide bg-gray-50">
          ${this.getCategoryName(category)}
        </div>
      `
      
      // Tags in this category
      tags.forEach((tag, index) => {
        const highlightedName = this.highlightMatch(tag.name, query)
        html += `
          <a href="/posts/tagged/${encodeURIComponent(tag.id || tag.name)}" 
             class="flex items-center px-4 py-3 hover:bg-gray-50 transition-colors duration-150 border-b border-gray-100 last:border-b-0"
             data-action="click->tag-search#selectResult">
            <div class="flex-1">
              <div class="font-medium text-gray-900">#${highlightedName}</div>
              ${tag.description ? `<div class="text-sm text-gray-500 truncate">${tag.description}</div>` : ''}
            </div>
            <div class="ml-3">
              <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${this.getCategoryBadgeClass(category)}">
                ${this.getCategoryName(category)}
              </span>
            </div>
          </a>
        `
      })
    })
    
    this.resultsTarget.innerHTML = html
    this.showDropdown()
    this.selectedIndex = -1
  }

  showNoResults(query) {
    this.resultsTarget.innerHTML = `
      <div class="px-4 py-6 text-center text-gray-500">
        <svg class="mx-auto h-12 w-12 text-gray-400 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
        </svg>
        <p class="text-sm">No tags found for "${query}"</p>
        <p class="text-xs text-gray-400 mt-1">Try a different search term</p>
      </div>
    `
    this.showDropdown()
  }

  highlightMatch(text, query) {
    const regex = new RegExp(`(${query})`, 'gi')
    return text.replace(regex, '<mark class="bg-yellow-200 px-1 rounded">$1</mark>')
  }

  getCategoryName(category) {
    const categoryMap = {
      'geographic': 'Geographic',
      'professional': 'Professional', 
      'country_region': 'Diaspora',
      'special_project': 'Special Projects'
    }
    return categoryMap[category] || 'General'
  }

  getCategoryBadgeClass(category) {
    const classMap = {
      'geographic': 'bg-blue-100 text-blue-800',
      'professional': 'bg-green-100 text-green-800',
      'country_region': 'bg-purple-100 text-purple-800',
      'special_project': 'bg-yellow-100 text-yellow-800'
    }
    return classMap[category] || 'bg-gray-100 text-gray-800'
  }

  handleKeydown(event) {
    const items = this.resultsTarget.querySelectorAll('a')
    
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.updateSelection(items)
        break
      case 'ArrowUp':
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, -1)
        this.updateSelection(items)
        break
      case 'Enter':
        event.preventDefault()
        if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
          items[this.selectedIndex].click()
        } else {
          // Submit the form if no item is selected
          this.element.querySelector('form').submit()
        }
        break
      case 'Escape':
        this.hideDropdown()
        this.inputTarget.blur()
        break
    }
  }

  updateSelection(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add('bg-gray-100')
        item.scrollIntoView({ block: 'nearest' })
      } else {
        item.classList.remove('bg-gray-100')
      }
    })
  }

  selectResult(event) {
    // Let the default link behavior happen
    this.hideDropdown()
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }

  showDropdown() {
    this.dropdownTarget.classList.remove('hidden')
  }

  hideDropdown() {
    this.dropdownTarget.classList.add('hidden')
    this.selectedIndex = -1
  }
}