module HtmlProcessor
extend ActiveSupport::Concern

included do
    include ActionView::Helpers::SanitizeHelper
    include ActionView::Helpers::TextHelper
end

# Comprehensive list of allowed HTML tags
ALLOWED_TAGS = %w[
    p br hr a div span
    b i em strong
    ul ol li
    h1 h2 h3 h4 h5 h6
    blockquote pre code
    table thead tbody tr td th
    img figure figcaption
].freeze

# Define allowed attributes for specific tags
ALLOWED_ATTRIBUTES = {
    "a" => %w[href target rel],
    "img" => %w[src alt title],
    "figure" => %w[class],
    "figcaption" => %w[class]
}.freeze


def process_html(text)
    return "" if text.blank?

    # Initial sanitization
    safe_html = sanitize(text.to_s, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)

    # Process with Nokogiri
    doc = Nokogiri::HTML.fragment(safe_html)

    process_text_nodes(doc)
    secure_links(doc)
    clean_attributes(doc)

    # Final sanitization and cleanup
    sanitize(doc.to_html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES).strip
end

private

def process_text_nodes(doc)
    # Text nodes are now processed without auto-linking
    # This method is kept for backward compatibility
    # but doesn't modify the document anymore
end

def secure_links(doc)
    doc.css("a").each do |link|
    href = link["href"]

    # Ensure href is present and uses a safe protocol
    if href.present? && href.match?(/\A(?:http|https):\/\//i)
        link["target"] = "_blank"
        link["rel"] = "noopener noreferrer"
    else
        # Remove links with unsafe protocols
        link.replace(link.inner_html)
    end
    end
end

def clean_attributes(doc)
    doc.css("*").each do |element|
    allowed_attrs = ALLOWED_ATTRIBUTES[element.name] || []

    element.attributes.each_key do |attr|
        unless allowed_attrs.include?(attr)
        element.remove_attribute(attr)
        end
    end
    end
end

end
