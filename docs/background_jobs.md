# Background Jobs in Naija-Forum

This document provides comprehensive guidance on working with background jobs in the Naija-Forum application. We use the Solid Queue framework for processing background jobs, which is built on top of Rails' Active Job API.

## How Solid Queue is Configured

Solid Queue is Rails' newest official job processing system that stores jobs in your application's primary database, providing reliability and simplicity.

### Configuration in the Application

1. **Gemfile**:
   ```ruby
   gem "solid_queue"
   ```

2. **Environment Configuration**:
   - In `config/environments/development.rb` and `config/environments/production.rb`:
   ```ruby
   config.active_job.queue_adapter = :solid_queue
   ```

3. **Database Schema**:
   Solid Queue uses several database tables to manage job queuing and execution:
   - `solid_queue_jobs`: Stores job data
   - `solid_queue_scheduled_executions`: For delayed/scheduled jobs
   - `solid_queue_ready_executions`: Jobs ready to be performed
   - `solid_queue_claimed_executions`: Jobs currently being processed
   - `solid_queue_blocked_executions`: Jobs waiting for others to complete
   - `solid_queue_failed_executions`: Failed jobs
   - `solid_queue_semaphores`: For concurrency control
   - `solid_queue_processes`: Information about worker processes

### Running Solid Queue Workers

```bash
# Starting the worker process
bin/rails solid_queue:start

# Alternatively, start a worker process with Daemon flags
bin/rails solid_queue:start --daemon --pid-file=tmp/pids/solid_queue.pid

# Stopping a daemonized worker
bin/rails solid_queue:stop --pid-file=tmp/pids/solid_queue.pid
```

## Available Job Classes

### `ApplicationJob`
Base class for all jobs in the application. Defines common functionality and default queue settings.

### `EmailNotificationJob`
Handles sending various types of email notifications to users.

**Purpose**: Ensures that emails don't block request processing and can be retried if delivery fails.

**Parameters**:
- `user_id`: ID of the user to notify
- `notification_type`: Type of notification (e.g., "welcome", "new_comment", "new_like")
- `content_id`: (Optional) ID of relevant content
- `data`: (Optional) Additional data for the notification

### `ContentIndexingJob`
Indexes new or updated content in the search system.

**Purpose**: Ensures that search indexing happens in the background to keep the application responsive.

**Parameters**:
- `content_id`: ID of the content to index
- `content_type`: Type of content (e.g., "post", "comment")

### `ReportGenerationJob`
Generates various types of reports that may be computationally intensive.

**Purpose**: Handles time-consuming report generation tasks asynchronously.

**Parameters**:
- `report_type`: Type of report to generate
- `parameters`: Hash of parameters specific to the report
- `user_id`: ID of the user who requested the report

## How to Enqueue New Jobs

You can enqueue jobs using the Active Job API from anywhere in your application:

### Immediate Execution:

```ruby
# Enqueue an email notification job
EmailNotificationJob.perform_later(user.id, "welcome")

# Enqueue a content indexing job
ContentIndexingJob.perform_later(post.id, "post")

# Enqueue a report generation job with parameters
ReportGenerationJob.perform_later("user_activity", { start_date: 1.month.ago, end_date: Time.current }, current_user.id)
```

### Scheduled Execution:

```ruby
# Schedule a job to run later
EmailNotificationJob.set(wait: 1.hour).perform_later(user.id, "reminder")

# Schedule a job at a specific time
ReportGenerationJob.set(wait_until: Date.tomorrow.noon).perform_later("daily_summary", { date: Date.today }, admin.id)
```

### With Custom Queue:

```ruby
# Specify a custom queue
EmailNotificationJob.set(queue: "high_priority").perform_later(user.id, "security_alert")
```

## Monitoring and Troubleshooting Jobs

### Database Inspection

You can query the Solid Queue tables directly to see job status:

```ruby
# Count jobs in different states
SolidQueue::Job.count                          # All jobs
SolidQueue::ScheduledExecution.count           # Scheduled jobs
SolidQueue::ReadyExecution.count               # Jobs ready to run
SolidQueue::ClaimedExecution.count             # Jobs being processed
SolidQueue::FailedExecution.count              # Failed jobs

# Find failed jobs for a specific class
failed_jobs = SolidQueue::Job.joins(:failed_execution)
                             .where(class_name: "EmailNotificationJob")
```

### Rails Console Inspection

```ruby
# Get counts of jobs by class name
SolidQueue::Job.group(:class_name).count

# Check failed jobs with their errors
SolidQueue::FailedExecution.includes(:job).map do |failed|
  { 
    job_class: failed.job.class_name,
    error: failed.error_message,
    failed_at: failed.created_at
  }
end
```

### Retry Failed Jobs

```ruby
# Retry a specific failed job
failed_execution = SolidQueue::FailedExecution.find(execution_id)
failed_execution.retry!

# Retry all failed jobs for a specific class
SolidQueue::FailedExecution.includes(:job)
                          .where(jobs: { class_name: "EmailNotificationJob" })
                          .find_each(&:retry!)
```

### Monitoring in Production

Consider adding monitoring for your Solid Queue workers:

1. **Health Checks**: Implement worker health checks
2. **Prometheus Metrics**: Expose metrics about queue size and processing time
3. **Logging**: Add detailed logging to track job execution
4. **Alerting**: Set up alerts for queue backlog or worker failures

## Best Practices for Creating New Job Classes

1. **Inherit from ApplicationJob**:
   ```ruby
   class MyNewJob < ApplicationJob
     queue_as :default
     
     def perform(*args)
       # Job implementation
     end
   end
   ```

2. **Keep Jobs Idempotent**: 
   Jobs should be safe to run multiple times in case of retries.

3. **Handle Errors Properly**:
   ```ruby
   def perform(user_id, action)
     user = User.find_by(id: user_id)
     return unless user  # Gracefully handle missing records
     
     begin
       # Perform action
     rescue StandardError => e
       Rails.logger.error("Failed to process job: #{e.message}")
       # Consider whether to re-raise (will retry) or not
       raise
     end
   end
   ```

4. **Pass IDs, Not Objects**:
   Pass database IDs instead of entire Active Record objects to jobs.

5. **Use Meaningful Queue Names**:
   ```ruby
   class UrgentNotificationJob < ApplicationJob
     queue_as :high_priority
     # ...
   end
   ```

6. **Add Retry Configuration**:
   ```ruby
   class ApiIntegrationJob < ApplicationJob
     retry_on NetworkError, wait: :exponentially_longer, attempts: 5
     discard_on ActiveRecord::RecordNotFound
     # ...
   end
   ```

7. **Add Logging**:
   ```ruby
   def perform(user_id, action)
     Rails.logger.info("Starting #{action} for user #{user_id}")
     # Job logic
     Rails.logger.info("Completed #{action} for user #{user_id}")
   end
   ```

8. **Test Your Jobs**:
   Create tests for your job classes to ensure they function correctly.
   ```ruby
   # In RSpec
   RSpec.describe EmailNotificationJob, type: :job do
     describe "#perform" do
       it "sends a welcome email" do
         user = create(:user)
         expect { EmailNotificationJob.perform_now(user.id, "welcome") }
           .to change { ActionMailer::Base.deliveries.count }.by(1)
       end
     end
   end
   ```

9. **Document Job Classes**:
   Add clear documentation to your job classes to make it easy for other developers to understand their purpose and usage.

By following these guidelines, you can effectively manage background processing in your Naija-Forum application.

