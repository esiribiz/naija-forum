module ApplicationHelper
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
end
