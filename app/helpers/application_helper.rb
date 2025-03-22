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
end
