import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "stickyHeader",
    "scrollToTopBtn",
    "fabToggle",
    "fabMenu",
    "shareModal",
    "shareModalContent",
    "shareModalBackdrop",
    "closeShareModal",
    "shareFab",
    "copyUrlBtn",
    "shareUrlInput",
    "copyMessage",
    "commentsFab",
    "commentsSection",
    "printFab"
  ]

  connect() {
    this.lastScrollY = window.scrollY
    this.boundHandleScroll = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.boundHandleScroll)
    
    // Initialize sticky header position
    this.handleScroll()
  }

  disconnect() {
    if (this.boundHandleScroll) {
      window.removeEventListener('scroll', this.boundHandleScroll)
    }
  }

  handleScroll() {
    if (!this.hasStickyHeaderTarget) return
    
    const currentScrollY = window.scrollY
    
    // Show/hide sticky header based on scroll position and direction
    if (currentScrollY > 300) {
      if (currentScrollY < this.lastScrollY) {
        // Scrolling up - show header
        this.stickyHeaderTarget.classList.remove('-translate-y-full', 'opacity-0')
        this.stickyHeaderTarget.classList.add('translate-y-0', 'opacity-100')
      } else {
        // Scrolling down - hide header
        this.stickyHeaderTarget.classList.remove('translate-y-0', 'opacity-100')
        this.stickyHeaderTarget.classList.add('-translate-y-full', 'opacity-0')
      }
    } else {
      // At the top - hide header
      this.stickyHeaderTarget.classList.remove('translate-y-0', 'opacity-100')
      this.stickyHeaderTarget.classList.add('-translate-y-full', 'opacity-0')
    }
    
    this.lastScrollY = currentScrollY
  }

  scrollToTop(event) {
    event.preventDefault()
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    })
  }

  toggleFabMenu(event) {
    event.preventDefault()
    if (!this.hasFabMenuTarget) return
    
    if (this.fabMenuTarget.classList.contains('hidden')) {
      this.fabMenuTarget.classList.remove('hidden', 'scale-95', 'opacity-0')
      this.fabMenuTarget.classList.add('flex', 'scale-100', 'opacity-100')
    } else {
      this.fabMenuTarget.classList.remove('flex', 'scale-100', 'opacity-100')
      this.fabMenuTarget.classList.add('scale-95', 'opacity-0')
      setTimeout(() => {
        this.fabMenuTarget.classList.add('hidden')
      }, 300)
    }
  }

  openShareModal(event) {
    event.preventDefault()
    if (!this.hasShareModalTarget || !this.hasShareModalContentTarget) return
    
    this.shareModalTarget.classList.remove('hidden')
    this.shareModalTarget.classList.add('flex')
    
    setTimeout(() => {
      this.shareModalContentTarget.classList.remove('scale-95', 'opacity-0')
      this.shareModalContentTarget.classList.add('scale-100', 'opacity-100')
    }, 10)
  }

  closeShareModal(event) {
    event.preventDefault()
    if (!this.hasShareModalTarget || !this.hasShareModalContentTarget) return
    
    this.shareModalContentTarget.classList.remove('scale-100', 'opacity-100')
    this.shareModalContentTarget.classList.add('scale-95', 'opacity-0')
    
    setTimeout(() => {
      this.shareModalTarget.classList.remove('flex')
      this.shareModalTarget.classList.add('hidden')
    }, 300)
  }

  copyUrl(event) {
    event.preventDefault()
    if (!this.hasShareUrlInputTarget) return
    
    this.shareUrlInputTarget.select()
    document.execCommand('copy')
    
    if (this.hasCopyMessageTarget) {
      this.copyMessageTarget.classList.remove('opacity-0')
      this.copyMessageTarget.classList.add('opacity-100')
      
      setTimeout(() => {
        this.copyMessageTarget.classList.remove('opacity-100')
        this.copyMessageTarget.classList.add('opacity-0')
      }, 2000)
    }
  }

  share(event) {
    event.preventDefault()
    const platform = event.currentTarget.dataset.share
    const url = encodeURIComponent(window.location.href)
    const title = encodeURIComponent(document.title)
    
    let shareUrl = ''
    
    switch (platform) {
      case 'twitter':
        shareUrl = `https://twitter.com/intent/tweet?text=${title}&url=${url}`
        break
      case 'facebook':
        shareUrl = `https://www.facebook.com/sharer/sharer.php?u=${url}`
        break
      case 'linkedin':
        shareUrl = `https://www.linkedin.com/sharing/share-offsite/?url=${url}`
        break
      case 'whatsapp':
        shareUrl = `https://api.whatsapp.com/send?text=${title}%20${url}`
        break
    }
    
    if (shareUrl) {
      window.open(shareUrl, '_blank').focus()
    }
  }

  scrollToComments(event) {
    event.preventDefault()
    if (!this.hasCommentsSectionTarget) return
    
    this.commentsSectionTarget.scrollIntoView({ behavior: 'smooth' })
  }

  print(event) {
    event.preventDefault()
    window.print()
  }
}