# frozen_string_literal: true

# HtmlProcessor provides HTML sanitization functionality for user-generated content
# It allows specific safe tags and attributes while stripping potentially dangerous elements
module HtmlProcessor
  extend ActiveSupport::Concern

  # Sanitizes HTML content, allowing only safe tags and attributes
  # @param content [String] the HTML content to sanitize
  # @return [String] sanitized HTML with only allowed tags and attributes
  def process_html(content)
    return "" if content.blank?

    # Define allowed tags (common formatting elements)
    allowed_tags = %w[
      p br strong b em i u s code pre
      ul ol li dl dt dd
      h1 h2 h3 h4 h5 h6
      blockquote q cite
      a img
      table thead tbody tfoot tr td th
      hr
    ]

    # Define allowed attributes for specific tags
    allowed_attributes = {
      "a" => %w[href title rel target],
      "img" => %w[src alt title width height],
      "table" => %w[summary width border cellspacing cellpadding align],
      "th" => %w[colspan rowspan scope],
      "td" => %w[colspan rowspan],
      "all" => %w[class id style] # Attributes allowed on all elements
    }

    # Use Rails' sanitize helper with custom configuration
    ActionController::Base.helpers.sanitize(
      content,
      tags: allowed_tags,
      attributes: allowed_attributes
    )
  end

  # Processes HTML content by sanitizing
  # @param content [String] the content to process
  # @return [String] processed content
  def process_content(content)
    process_html(content)
  end
end
