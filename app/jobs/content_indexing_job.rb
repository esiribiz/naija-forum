class ContentIndexingJob < ApplicationJob
  queue_as :default

  # Retry failed jobs up to 3 times with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Discard the job if the record no longer exists
  discard_on ActiveRecord::RecordNotFound

  # @param content_id [Integer] ID of the content to be indexed
  # @param content_type [String] Type of content ('post', 'comment', etc.)
  # @return [void]
  def perform(content_id, content_type)
    Rails.logger.info "Indexing #{content_type} with ID #{content_id}"

    # Find the corresponding model based on content_type
    case content_type.to_s.downcase
    when "post"
      content = Post.find(content_id)
    when "comment"
      content = Comment.find(content_id)
    when "category"
      content = Category.find(content_id)
    when "tag"
      content = Tag.find(content_id)
    else
      Rails.logger.error "Unknown content type: #{content_type}"
      raise ArgumentError, "Unknown content type: #{content_type}"
    end

    # Index the content using the search service
    index_content(content, content_type)

    Rails.logger.info "Successfully indexed #{content_type} with ID #{content_id}"
  rescue StandardError => e
    Rails.logger.error "Error indexing #{content_type} with ID #{content_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise # Re-raise to trigger retry mechanism
  end

  private

  # Index the content using a search service
  # @param content [ActiveRecord::Base] The content object to index
  # @param content_type [String] Type of content for indexing
  # @return [Boolean] Whether indexing was successful
  def index_content(content, content_type)
    # NOTE: This is a placeholder for the actual search indexing implementation
    # In a real application, you would use a real search service like Elasticsearch,
    # Algolia, or Rails' built-in search capabilities

    # Example implementation with a hypothetical SearchIndexer service
    # Replace this with your actual search indexing service
    search_indexer = SearchIndexer.new

    # Extract the relevant attributes for indexing based on content type
    attributes = extract_attributes(content, content_type)

    # Send to search index
    search_indexer.index(
      id: content.id,
      type: content_type,
      attributes: attributes
    )
  end

  # Extract attributes for indexing based on content type
  # @param content [ActiveRecord::Base] The content object
  # @param content_type [String] Type of content
  # @return [Hash] Attributes for indexing
  def extract_attributes(content, content_type)
    case content_type.to_s.downcase
    when "post"
      {
        title: content.title,
        body: content.body,
        author: content.user&.username,
        category: content.category&.name,
        tags: content.tags&.pluck(:name),
        created_at: content.created_at,
        updated_at: content.updated_at
      }
    when "comment"
      {
        body: content.body,
        author: content.user&.username,
        post_id: content.post_id,
        created_at: content.created_at,
        updated_at: content.updated_at
      }
    when "category"
      {
        name: content.name,
        description: content.description
      }
    when "tag"
      {
        name: content.name
      }
    else
      {}
    end
  end
end
