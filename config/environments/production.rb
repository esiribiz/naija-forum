require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  config.active_storage.service = :amazon
  config.assume_ssl = true
  config.force_ssl = true

  config.log_tags = [ :request_id ]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  config.cache_store = :solid_cache_store
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # 🔐 HOST AUTHORIZATION — UNCOMMENTED & CONFIGURED
  config.hosts = [
    ENV.fetch("APPLICATION_HOST", "your-domain.com"),
    /.*\.#{Regexp.quote(ENV.fetch("APPLICATION_HOST", "your-domain.com"))}/
  ]
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # ✉️ MAILER
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = { host: ENV.fetch("APPLICATION_HOST", "your-domain.com") }

  if config.action_mailer.delivery_method == :smtp
    config.action_mailer.smtp_settings = {
      user_name: ENV["SMTP_USERNAME"],
      password: ENV["SMTP_PASSWORD"],
      address: ENV.fetch("SMTP_ADDRESS", "smtp.gmail.com"),
      port: ENV.fetch("SMTP_PORT", 587),
      domain: ENV.fetch("SMTP_DOMAIN", ENV.fetch("APPLICATION_HOST", "your-domain.com")), # 👈 Added
      authentication: :plain,
      enable_starttls_auto: true,
      open_timeout: 10,
      read_timeout: 10
    }
  end

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]
end
