import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "suggestions"]
  
  connect() {
    this.suggestedTags = this.buildSuggestedTags()
    this.setupSuggestions()
    this.loadApprovedTags()
  }
  
  buildSuggestedTags() {
    return {
      geographic: [
        'Abia', 'Abuja', 'Adamawa', 'AkwaIbom', 'Anambra', 'Bauchi', 'Bayelsa', 'Benue', 'Borno', 'CrossRiver',
        'Delta', 'Ebonyi', 'Edo', 'Ekiti', 'Enugu', 'Gombe', 'Imo', 'Jigawa', 'Kaduna', 'Kano', 'Katsina', 'Kebbi',
        'Kogi', 'Kwara', 'Lagos', 'Nasarawa', 'Niger', 'Ogun', 'Ondo', 'Osun', 'Oyo', 'Plateau', 'Rivers', 'Sokoto',
        'Taraba', 'Yobe', 'Zamfara'
      ],
      professional: [
        'Technology', 'Education', 'Health', 'Business', 'Infrastructure', 'Politics', 'Economy',
        'Governance', 'Startups', 'Innovation', 'Agriculture', 'Energy', 'Finance', 'Science', 'Culture',
        'DiasporaLife', 'Opportunities', 'Policy', 'Migration', 'Leadership', 'SocialImpact',
        'YouthEmpowerment', 'WomenInTech', 'Research', 'Volunteerism'
      ],
      country_region: [
        'USA', 'UK', 'Canada', 'Germany', 'France', 'Finland', 'Sweden', 'Norway', 'Denmark', 'Netherlands',
        'Italy', 'Spain', 'UAE', 'SouthAfrica', 'Australia', 'Japan'
      ],
      special_project: [
        'BuildNaija', 'DiasporaInvest', 'Mentorship', 'NaijaTech', 'CleanEnergy', 'ThinkNaija',
        'ReturnHome', 'NaijaRising'
      ]
    }
  }
  
  setupSuggestions() {
    const content = document.getElementById('tag-suggestions-content')
    if (!content) return
    
    // Build suggestions by category
    Object.entries(this.suggestedTags).forEach(([category, tags]) => {
      const categoryDiv = document.createElement('div')
      categoryDiv.className = 'mb-3'
      
      const categoryName = this.getCategoryDisplayName(category)
      const categoryColor = this.getCategoryColor(category)
      
      categoryDiv.innerHTML = `
        <div class="flex items-center mb-2">
          <div class="w-2 h-2 ${categoryColor} rounded-full mr-2"></div>
          <h5 class="text-xs font-semibold text-gray-600 uppercase">${categoryName}</h5>
        </div>
        <div class="flex flex-wrap gap-1">
          ${tags.map(tag => `
            <button type="button" 
                    data-tag="${tag}" 
                    data-category="${category}"
                    class="px-2 py-1 text-xs bg-gray-100 hover:${categoryColor.replace('bg-', 'bg-').replace('-500', '-100')} text-gray-700 hover:text-gray-800 rounded border border-gray-200 hover:border-gray-300 transition duration-150"
                    onclick="this.closest('[data-controller=tags]').querySelector('[data-tags-target=input]').value += (this.closest('[data-controller=tags]').querySelector('[data-tags-target=input]').value ? ', ' : '') + '${tag}'"
            >${tag}</button>
          `).join('')}
        </div>
      `
      
      content.appendChild(categoryDiv)
    })
  }
  
  getCategoryDisplayName(category) {
    const names = {
      geographic: 'Geographic (Nigerian States)',
      professional: 'Professional & Topics',
      country_region: 'Diaspora Countries',
      special_project: 'Special Projects'
    }
    return names[category] || category
  }
  
  getCategoryColor(category) {
    const colors = {
      geographic: 'bg-blue-500',
      professional: 'bg-green-500',
      country_region: 'bg-purple-500',
      special_project: 'bg-yellow-500'
    }
    return colors[category] || 'bg-gray-500'
  }
  
  filterSuggestions(event) {
    const query = event.target.value
    
    // Use approved tags API if available, fallback to static suggestions
    if (this.approvedTags) {
      this.filterApprovedSuggestions(query)
    } else {
      this.filterStaticSuggestions(query)
    }
  }
  
  filterStaticSuggestions(query) {
    const currentTags = query.split(',').map(t => t.trim())
    const lastTag = currentTags[currentTags.length - 1]
    
    if (lastTag.length < 2) {
      this.showAllSuggestions()
      return
    }
    
    const content = document.getElementById('tag-suggestions-content')
    if (!content) return
    
    // Filter and show matching tags
    const matchingTags = []
    Object.entries(this.suggestedTags).forEach(([category, tags]) => {
      const matches = tags.filter(tag => 
        tag.toLowerCase().includes(lastTag.toLowerCase()) &&
        !currentTags.slice(0, -1).includes(tag)
      )
      if (matches.length > 0) {
        matchingTags.push({ category, tags: matches })
      }
    })
    
    if (matchingTags.length === 0) {
      content.innerHTML = '<p class="text-xs text-gray-500 italic">No matching suggestions</p>'
      return
    }
    
    content.innerHTML = ''
    matchingTags.forEach(({ category, tags }) => {
      const categoryDiv = document.createElement('div')
      categoryDiv.className = 'mb-2'
      
      const categoryName = this.getCategoryDisplayName(category)
      const categoryColor = this.getCategoryColor(category)
      
      categoryDiv.innerHTML = `
        <div class="flex items-center mb-1">
          <div class="w-2 h-2 ${categoryColor} rounded-full mr-2"></div>
          <h5 class="text-xs font-semibold text-gray-600">${categoryName}</h5>
        </div>
        <div class="flex flex-wrap gap-1">
          ${tags.slice(0, 8).map(tag => `
            <button type="button" 
                    data-tag="${tag}" 
                    data-category="${category}"
                    class="px-2 py-1 text-xs bg-gray-100 hover:${categoryColor.replace('bg-', 'bg-').replace('-500', '-100')} text-gray-700 hover:text-gray-800 rounded border border-gray-200 hover:border-gray-300 transition duration-150"
                    onclick="this.replaceLastTag('${tag}')"
            >${tag}</button>
          `).join('')}
        </div>
      `
      
      content.appendChild(categoryDiv)
    })
  }
  
  showAllSuggestions() {
    if (this.approvedTags) {
      this.setupApprovedSuggestions()
    } else {
      this.setupSuggestions()
    }
  }
  
  showSuggestions() {
    this.suggestionsTarget.classList.remove('hidden')
  }
  
  hideSuggestions() {
    // Delay hiding to allow clicking on suggestions
    setTimeout(() => {
      this.suggestionsTarget.classList.add('hidden')
    }, 200)
  }
  
  replaceLastTag(newTag) {
    const input = this.inputTarget
    const currentValue = input.value
    const tags = currentValue.split(',').map(t => t.trim())
    
    // Replace the last tag with the selected one
    tags[tags.length - 1] = newTag
    
    input.value = tags.join(', ')
    input.focus()
    this.hideSuggestions()
  }
  
  async loadApprovedTags() {
    try {
      const response = await fetch('/approved_tags/suggestions.json')
      if (response.ok) {
        this.approvedTags = await response.json()
        this.setupApprovedSuggestions()
      }
    } catch (error) {
      console.log('Could not load approved tags, using fallback:', error)
      // Fallback to static suggestions if API fails
    }
  }
  
  setupApprovedSuggestions() {
    if (!this.approvedTags) return
    
    const content = document.getElementById('tag-suggestions-content')
    if (!content) return
    
    content.innerHTML = ''
    
    Object.entries(this.approvedTags).forEach(([category, tags]) => {
      if (tags.length === 0) return
      
      const categoryDiv = document.createElement('div')
      categoryDiv.className = 'mb-3'
      
      const categoryName = this.getCategoryDisplayName(category)
      const categoryColor = this.getCategoryColor(category)
      
      categoryDiv.innerHTML = `
        <div class="flex items-center mb-2">
          <div class="w-2 h-2 ${categoryColor} rounded-full mr-2"></div>
          <h5 class="text-xs font-semibold text-gray-600 uppercase">${categoryName}</h5>
        </div>
        <div class="flex flex-wrap gap-1">
          ${tags.map(tag => `
            <button type="button" 
                    data-tag="${tag.name}" 
                    data-category="${tag.category}"
                    class="px-2 py-1 text-xs ${tag.badge_color || 'bg-gray-100'} hover:opacity-80 text-gray-700 hover:text-gray-800 rounded border border-gray-200 hover:border-gray-300 transition duration-150"
                    onclick="this.closest('[data-controller=tags]').querySelector('[data-tags-target=input]').value += (this.closest('[data-controller=tags]').querySelector('[data-tags-target=input]').value ? ', ' : '') + '${tag.name}'"
            >${tag.name}</button>
          `).join('')}
        </div>
      `
      
      content.appendChild(categoryDiv)
    })
  }
  
  async filterApprovedSuggestions(query) {
    const lastTag = query.split(',').pop().trim()
    
    if (lastTag.length < 2) {
      this.setupApprovedSuggestions()
      return
    }
    
    try {
      const response = await fetch(`/approved_tags/suggestions.json?q=${encodeURIComponent(lastTag)}`)
      if (response.ok) {
        const filteredTags = await response.json()
        this.displayFilteredTags(filteredTags, lastTag)
      }
    } catch (error) {
      console.log('Could not filter approved tags:', error)
      this.filterSuggestions({ target: { value: query } })
    }
  }
  
  displayFilteredTags(tags, query) {
    const content = document.getElementById('tag-suggestions-content')
    if (!content) return
    
    const hasResults = Object.values(tags).some(tagList => tagList.length > 0)
    
    if (!hasResults) {
      content.innerHTML = `
        <div class="text-center py-4">
          <p class="text-xs text-gray-500 italic mb-2">No matching approved tags found</p>
          <p class="text-xs text-green-600">"${query}" will be submitted for approval</p>
        </div>
      `
      return
    }
    
    content.innerHTML = ''
    Object.entries(tags).forEach(([category, tagList]) => {
      if (tagList.length === 0) return
      
      const categoryDiv = document.createElement('div')
      categoryDiv.className = 'mb-2'
      
      const categoryName = this.getCategoryDisplayName(category)
      const categoryColor = this.getCategoryColor(category)
      
      categoryDiv.innerHTML = `
        <div class="flex items-center mb-1">
          <div class="w-2 h-2 ${categoryColor} rounded-full mr-2"></div>
          <h5 class="text-xs font-semibold text-gray-600">${categoryName}</h5>
        </div>
        <div class="flex flex-wrap gap-1">
          ${tagList.slice(0, 8).map(tag => `
            <button type="button" 
                    data-tag="${tag.name}" 
                    data-category="${tag.category}"
                    class="px-2 py-1 text-xs ${tag.badge_color || 'bg-gray-100'} hover:opacity-80 text-gray-700 hover:text-gray-800 rounded border border-gray-200 hover:border-gray-300 transition duration-150"
                    onclick="this.replaceLastTag('${tag.name}')"
            >${tag.name}</button>
          `).join('')}
        </div>
      `
      
      content.appendChild(categoryDiv)
    })
  }
}
