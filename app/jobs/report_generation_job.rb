class ReportGenerationJob < ApplicationJob
  queue_as :default

  # Set retry limits and backoff strategy
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Define report types
  REPORT_TYPES = %w[user_activity content_engagement trending_topics post_analytics].freeze

  # Generates a report based on the specified type and parameters
  #
  # @param report_type [String] type of report to generate (e.g., 'user_activity', 'content_engagement')
  # @param parameters [Hash] parameters for the report (e.g., date range, specific filters)
  # @param user_id [Integer] ID of the user who requested the report
  def perform(report_type, parameters = {}, user_id = nil)
    unless REPORT_TYPES.include?(report_type)
      Rails.logger.error("Invalid report type: #{report_type}")
      return
    end

    Rails.logger.info("Generating #{report_type} report for user #{user_id} with parameters: #{parameters}")
    begin
      # Find the user who requested the report
      user = User.find_by(id: user_id) if user_id.present?

      # Generate the report based on type
      report_data = generate_report(report_type, parameters)

      # Create a filename for the report
      filename = "#{report_type}_report_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"

      # Store the report using ActiveStorage
      report_blob = store_report(report_data, filename, report_type)

      # Create a record of the report (assuming there's a Report model)
      report_record = create_report_record(report_type, parameters, user_id, report_blob.id)

      # Notify the user that the report is ready
      notify_user(user, report_record) if user.present?

      Rails.logger.info("Successfully generated and stored #{report_type} report for user #{user_id}")
    rescue StandardError => e
      Rails.logger.error("Error generating #{report_type} report: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise # Re-raise to trigger retry mechanism
    end
  end

  private

  # Generate report data based on type and parameters
  def generate_report(report_type, parameters)
    case report_type
    when "user_activity"
      generate_user_activity_report(parameters)
    when "content_engagement"
      generate_content_engagement_report(parameters)
    when "trending_topics"
      generate_trending_topics_report(parameters)
    when "post_analytics"
      generate_post_analytics_report(parameters)
    else
      raise ArgumentError, "Unsupported report type: #{report_type}"
    end
  end

  # Generate user activity report
  def generate_user_activity_report(parameters)
    start_date = parameters[:start_date] || 30.days.ago
    end_date = parameters[:end_date] || Time.current

    # Example query to get user activity data
    user_data = User.where(created_at: start_date..end_date)
      .left_joins(:posts, :comments)
      .group(:id)
      .select(
        "users.id, users.username, COUNT(DISTINCT posts.id) as post_count, " \
        "COUNT(DISTINCT comments.id) as comment_count, users.created_at"
      )

    # Convert to CSV
    generate_csv_data(
      user_data,
      ["ID", "Username", "Post Count", "Comment Count", "Join Date"],
      ->(user) { [user.id, user.username, user.post_count, user.comment_count, user.created_at] }
    )
  end

  # Generate content engagement report
  def generate_content_engagement_report(parameters)
    start_date = parameters[:start_date] || 30.days.ago
    end_date = parameters[:end_date] || Time.current
    content_type = parameters[:content_type] || "posts"

    if content_type == "posts"
      data = Post.where(created_at: start_date..end_date)
        .left_joins(:comments, :likes)
        .group(:id)
        .select(
          "posts.id, posts.title, COUNT(DISTINCT comments.id) as comment_count, " \
          "COUNT(DISTINCT likes.id) as like_count, posts.created_at"
        )

      generate_csv_data(
        data,
        ["ID", "Title", "Comment Count", "Like Count", "Created At"],
        ->(post) { [post.id, post.title, post.comment_count, post.like_count, post.created_at] }
      )
    else
      # Handle other content types similarly
      ""
    end
  end

  # Generate trending topics report
  def generate_trending_topics_report(parameters)
    days = parameters[:days] || 7
    limit = parameters[:limit] || 20

    trending = Tag.joins(:posts)
      .where("posts.created_at > ?", days.days.ago)
      .group("tags.id")
      .order("COUNT(posts.id) DESC")
      .limit(limit)
      .select("tags.id, tags.name, COUNT(posts.id) as post_count")

    generate_csv_data(
      trending,
      ["ID", "Tag Name", "Post Count"],
      ->(tag) { [tag.id, tag.name, tag.post_count] }
    )
  end

  # Generate post analytics report
  def generate_post_analytics_report(parameters)
    category_id = parameters[:category_id]
    start_date = parameters[:start_date] || 30.days.ago
    end_date = parameters[:end_date] || Time.current

    query = Post.where(created_at: start_date..end_date)
    query = query.where(category_id: category_id) if category_id.present?

    data = query.left_joins(:comments, :likes, :views)
      .group(:id)
      .select(
        "posts.id, posts.title, posts.user_id, COUNT(DISTINCT comments.id) as comment_count, " \
        "COUNT(DISTINCT likes.id) as like_count, COUNT(DISTINCT views.id) as view_count, " \
        "posts.created_at"
      )

    generate_csv_data(
      data,
      ["ID", "Title", "Author ID", "Comment Count", "Like Count", "View Count", "Created At"],
      ->(post) { [post.id, post.title, post.user_id, post.comment_count, post.like_count, post.view_count, post.created_at] }
    )
  end

  # Helper method to generate CSV data from ActiveRecord results
  def generate_csv_data(data, headers, row_proc)
    require "csv"

    CSV.generate do |csv|
      csv << headers
      data.each do |item|
        csv << row_proc.call(item)
      end
    end
  end

  # Store report data using ActiveStorage
  def store_report(report_data, filename, report_type)
    # Create a temporary file with the report data
    temp_file = Tempfile.new([File.basename(filename, ".*"), File.extname(filename)])
    temp_file.write(report_data)
    temp_file.rewind

    # Create a blob entry in ActiveStorage
    blob = ActiveStorage::Blob.create_and_upload!(
      io: temp_file,
      filename: filename,
      content_type: "text/csv",
      metadata: { report_type: report_type }
    )

    # Clean up the temporary file
    temp_file.close
    temp_file.unlink

    blob
  end

  # Create a record for the report (assuming Report model exists)
  def create_report_record(report_type, parameters, user_id, blob_id)
    # This is a placeholder. You would need to adjust based on your actual model structure
    Report.create!(
      report_type: report_type,
      parameters: parameters,
      user_id: user_id,
      blob_id: blob_id,
      status: "completed",
      generated_at: Time.current
    )
  rescue NoMethodError
    # If Report model doesn't exist, log an error but don't fail the job
    Rails.logger.error("Report model not found. Create a Report model to track generated reports.")
    OpenStruct.new(id: nil, report_type: report_type)
  end

  # Notify the user that their report is ready
  def notify_user(user, report)
    # Queue an email notification job
    EmailNotificationJob.perform_later(
      user.id,
      "report_ready",
      data: {
        report_id: report.id,
        report_type: report.report_type
      }
    )
  rescue NoMethodError
    Rails.logger.error("EmailNotificationJob not found or user doesn't have email method.")
  end
end
