source "https://rubygems.org"

# Comments and user interactions
gem 'acts_as_votable', '~> 0.14.0'    # For voting on comments
gem 'redcarpet', '~> 3.6'             # For markdown support
gem 'rinku', '~> 2.0'                 # For auto-linking
gem 'sanitize', '~> 6.0'              # For HTML sanitization
gem 'loofah', '~> 2.21'              # For HTML processing using Nokogiri
gem 'noticed', '~> 1.6'               # For notifications
gem 'kaminari', '~> 1.2'              # For pagination

# Caching
gem 'actionpack-page_caching'
gem 'actionpack-action_caching'
gem 'redis', '~> 5.0'         # For caching geocoder results and general Redis operations

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Security
gem 'rack-attack', '~> 6.7'           # Rate limiting and throttling
gem 'secure_headers', '~> 6.5'        # Security headers (HSTS, CSP, etc.)
gem 'rack-cors', '~> 2.0'             # Cross-Origin Resource Sharing (CORS) management
gem 'redis-objects', '~> 1.7'         # Redis for rate limiting and session storage
gem 'strong_password', '~> 0.0.10'    # Password strength validation
gem 'invisible_captcha', '~> 2.1'     # Bot protection without CAPTCHA
gem 'http-security', '~> 0.1'         # HTTP security utilities
gem 'bcrypt', '~> 3.1.7'              # Secure password hashing
gem 'geocoder', '~> 1.8'              # IP-based geolocation and geographic restrictions
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw x64_mingw jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
# See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
gem "debug", platforms: %i[ mri mingw x64_mingw ], require: "debug/prelude"

# Static analysis for security vulnerabilities [https://brakemanscanner.org/]
gem "brakeman", require: false

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

# Testing
gem 'rspec-rails'         # Testing framework for Rails
gem 'factory_bot_rails'   # Fixtures replacement with a more flexible syntax
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "rails_live_reload"
end

group :test do
# Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
gem "capybara"
gem "selenium-webdriver"

# Additional testing gems
gem 'faker'                           # Generate fake data for tests
gem 'shoulda-matchers'                # Additional RSpec matchers
gem 'database_cleaner-active_record'  # Clean test database between runs
gem 'timecop'                         # Time travel for testing time-dependent code
end

gem "devise", "~> 4.9"
gem 'devise-security'
gem "pundit", "~> 2.3"
