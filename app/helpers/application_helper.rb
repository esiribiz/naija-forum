module ApplicationHelper
  # Safely generate avatar URL, handling cases where signed_id cannot be generated
  def safe_avatar_url(user)
    return nil unless user&.persisted? && user.avatar&.attached?
    
    begin
      # Use polymorphic_url which is more reliable in different contexts
      if user.avatar.blob&.persisted?
        url_for(user.avatar)
      else
        nil
      end
    rescue ArgumentError => e
      Rails.logger.warn "Failed to generate avatar URL for user #{user.id}: #{e.message}"
      nil
    rescue => e
      Rails.logger.warn "Unexpected error generating avatar URL for user #{user.id}: #{e.message}"
      nil
    end
  end
  def time_in_hours_ago(time)
    # Get the time difference in words
    time_ago = distance_of_time_in_words(Time.current, time)

    # Replace 'hour' and 'hours' with 'hr' using regex
    time_ago.gsub(/hour(s)?/, "hr")
  end

  def highlight_text(text, term)
    return text if term.blank?

    regex = Regexp.new(Regexp.escape(term), Regexp::IGNORECASE)
    text.gsub(regex, '<span class="bg-yellow-300 px-1 rounded-md">\0</span>').html_safe
  end

  # Determine if current page should show the profile sidebar
  def user_focused_page?
    return false unless user_signed_in?
    
    # User profile pages
    return true if controller_name == "users" && action_name == "show"
    
    # Posts pages (when viewing user's own posts or creating posts)
    if controller_name == "posts"
      # New/create post pages
      return true if ["new", "create", "edit", "update"].include?(action_name)
      
      # Index page when filtering by current user's posts
      if action_name == "index" && params[:user].present?
        user = User.find_by(id: params[:user]) || User.find_by(username: params[:user])
        return true if user == current_user
      end
    end
    
    # Notifications pages
    return true if controller_name == "notifications"
    
    # User registration/settings pages (Devise)
    if controller_name == "registrations" && controller.class.name.include?("Users")
      return true if ["edit", "update"].include?(action_name)
    end
    
    # User profile editing
    return true if controller_name == "users" && ["edit", "update"].include?(action_name)
    
    false
  end
  
  # Online status indicator for users
  def online_status_badge(user, options = {})
    return '' unless user&.persisted?
    
    css_classes = options[:class] || 'inline-flex items-center'
    show_text = options.fetch(:show_text, true)
    size = options[:size] || 'sm' # sm, md, lg
    
    case size
    when 'lg'
      dot_size = 'w-3 h-3'
      text_size = 'text-sm'
      spacing = 'ml-2'
    when 'md'
      dot_size = 'w-2.5 h-2.5'
      text_size = 'text-xs'
      spacing = 'ml-1.5'
    else # sm
      dot_size = 'w-2 h-2'
      text_size = 'text-xs'
      spacing = 'ml-1'
    end
    
    if user.online?
      content_tag :span, class: "#{css_classes} text-green-600" do
        concat content_tag(:span, '', class: "#{dot_size} bg-green-500 rounded-full animate-pulse")
        concat content_tag(:span, 'Online', class: "#{text_size} font-medium #{spacing}") if show_text
      end
    elsif user.recently_active?
      content_tag :span, class: "#{css_classes} text-blue-600" do
        concat content_tag(:span, '', class: "#{dot_size} bg-blue-500 rounded-full")
        concat content_tag(:span, 'Recently Active', class: "#{text_size} #{spacing}") if show_text
      end
    else
      # Don't show anything for inactive users to avoid clutter
      ''.html_safe
    end
  end
  
  # Simple online dot indicator (no text)
  def online_dot(user, options = {})
    online_status_badge(user, options.merge(show_text: false))
  end
  
  # Online status with custom text
  def online_status_with_text(user, custom_text = nil)
    return '' unless user&.persisted?
    
    if user.online?
      content_tag :span, class: 'inline-flex items-center text-green-600' do
        concat content_tag(:span, '', class: 'w-2 h-2 bg-green-500 rounded-full animate-pulse mr-1')
        concat content_tag(:span, custom_text || 'Online now', class: 'text-xs font-medium')
      end
    elsif user.recently_active?
      content_tag :span, class: 'inline-flex items-center text-blue-600' do
        concat content_tag(:span, '', class: 'w-2 h-2 bg-blue-500 rounded-full mr-1')
        concat content_tag(:span, custom_text || "Active #{time_ago_in_words(user.last_sign_in_at)} ago", class: 'text-xs')
      end
    else
      ''.html_safe
    end
  end
  
  # Last seen text for user profiles
  def last_seen_text(user)
    return 'Never signed in' unless user.last_sign_in_at
    
    if user.online?
      content_tag :span, class: 'text-green-600 font-medium' do
        '🟢 Online now'
      end
    elsif user.recently_active?
      content_tag :span, class: 'text-blue-600' do
        "🔵 Active #{time_ago_in_words(user.last_sign_in_at)} ago"
      end
    else
      content_tag :span, class: 'text-gray-500' do
        "Last seen #{time_ago_in_words(user.last_sign_in_at)} ago"
      end
    end
  end
  
  # Time-based greeting helper
  def time_based_greeting(time = Time.current)
    hour = time.hour
    case hour
    when 5..11
      "Good Morning"
    when 12..17
      "Good Afternoon"
    when 18..21
      "Good Evening"
    else
      "Good Night"
    end
  end
  
  # Format current time for admin header
  def formatted_current_time(time = Time.current)
    time.strftime("%l:%M %p, %B %d, %Y").strip
  end

  # Safely autolink URLs in user-generated content and preserve line breaks
  # - Strips any existing HTML first
  # - Converts plain URLs/emails to clickable links
  # - Adds rel and target attributes for safety and SEO (ugc/nofollow)
  # - Preserves line breaks as <br>
  def linkify_content(text)
    # Remove any existing HTML tags
    stripped = sanitize(text.to_s, tags: [], attributes: [])

    # Auto-link URLs and emails, opening in a new tab with safe rel attributes
    linked = Rinku.auto_link(
      stripped,
      :all,
      'target="_blank" rel="nofollow ugc noopener noreferrer"'
    )

    # Preserve newlines
    with_breaks = linked.gsub(/\r?\n/, "<br>")

    # Final sanitize allowing only anchor and br tags
    sanitize(with_breaks, tags: %w[a br], attributes: %w[href target rel]).html_safe
  end
end
