# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Naija-Forum is a Ruby on Rails 8.0.1 community platform designed for Nigerian users, featuring:
- Category-based discussions with posts and threaded comments
- Rich authentication system with Devise and security features
- User profiles with following/follower relationships
- Tagging system and search functionality
- Rate limiting and VPN/proxy detection for security
- Background job processing with Solid Queue
- Redis-based caching and rate limiting

## Common Development Commands

### Environment Setup
```bash
# Install dependencies
bundle install
yarn install

# Database setup
bin/rails db:create db:migrate
bin/rails db:seed

# Start development server (with Foreman)
bin/dev

# Start individual services
bin/rails server
bin/rails tailwindcss:watch
```

### Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test categories
bundle exec rspec spec/models
bundle exec rspec spec/requests
bundle exec rspec spec/jobs

# Run a specific test file
bundle exec rspec spec/models/user_spec.rb
```

### Code Quality & Linting
```bash
# Ruby code linting
bundle exec rubocop

# Run security scanner
bin/brakeman
```

### Background Jobs
```bash
# Start Solid Queue workers
bin/rails solid_queue:start

# Note: On macOS, you may encounter fork() issues with Solid Queue
# For development, you can process jobs manually:
bin/rails runner "SolidQueue::ReadyExecution.limit(10).each(&:destroy)"

# Check job status
bin/rails runner "puts 'Jobs: #{SolidQueue::Job.count}, Ready: #{SolidQueue::ReadyExecution.count}, Failed: #{SolidQueue::FailedExecution.count}'"
```

### Docker Development
```bash
# Build and start containers
docker-compose up --build

# Setup database in container (first time)
docker-compose exec web bin/rails db:create db:migrate db:seed

# Run tests in container
docker-compose exec web bundle exec rspec
```

## Code Architecture

### Core Models and Relationships
- **User**: Central entity with Devise authentication, security questions, rate limiting via Redis
- **Post**: Belongs to User and Category, has many Comments and Tags, includes rate limiting and HTML processing
- **Category**: Has many Posts, supports image uploads via Active Storage
- **Comment**: Threaded commenting system with replies, belongs to Post and User
- **Tag**: Many-to-many relationship with Posts via PostTag join table

### Security Features
- Custom Devise controllers (`users/sessions_controller.rb`, `users/registrations_controller.rb`)
- IP geolocation service for detecting restricted locations and VPN/proxy usage
- Rate limiting with Redis (user login attempts, post creation limits)
- HTML sanitization and processing via concerns (`HtmlProcessor`)
- Strong password validation with complexity requirements
- Security questions system (optional)

### Background Job System
Uses Solid Queue (Rails 8 built-in) with these job classes:
- `EmailNotificationJob`: Handles email notifications
- `ContentIndexingJob`: Indexes content for search
- `ReportGenerationJob`: Generates reports asynchronously

### Concerns and Shared Behavior
- `HtmlProcessor`: Sanitizes and processes HTML content
- `SecurityEnforceable`: Security-related functionality
- `RateLimitable`: Redis-based rate limiting
- `Mentionable`: User mentioning in posts/comments

### Authorization
Uses Pundit gem with policies for:
- `PostPolicy`: Post creation, editing, deletion permissions
- `CommentPolicy`: Comment permissions
- `CategoryPolicy`: Category management
- `UserPolicy`: User profile access

### Frontend Stack
- Hotwire (Turbo + Stimulus) for interactive features
- Tailwind CSS for styling
- Stimulus controllers for JavaScript functionality (alerts, comments, notifications)

### Key Configuration Files
- `Procfile.dev`: Defines development processes (web server + CSS watching)
- `config/routes.rb`: Nested routes for categories/posts/comments
- `bin/dev`: Development startup script using Foreman

### Database Schema
- PostgreSQL as primary database
- Active Storage for file uploads (avatars, category images, post images)
- Solid Queue tables for background job management
- Redis for caching and rate limiting

### Testing Structure
- RSpec with Factory Bot for test data
- System tests with Capybara and Selenium
- Security and job-specific test coverage
- Database cleaner and time travel support (Timecop)

### Deployment
- Docker support with multi-stage builds
- Kamal deployment configuration
- Heroku deployment ready
- Thruster for production server optimization
