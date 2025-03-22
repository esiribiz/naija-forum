# Naija-Forum

## Overview

Naija-Forum is a community platform designed specifically for Nigerian users to connect, share ideas, and engage in meaningful discussions. Built with Ruby on Rails, this forum application provides a robust and secure environment for users to interact through categorized discussions.

### Key Features

- **Category-based Discussions**: Organize conversations by topics and interests
- **Rich Content Posting**: Create and share formatted posts with attachments
- **Interactive Comments**: Engage with posts through threaded comments
- **Tagging System**: Find related content through a comprehensive tagging system
- **User Authentication**: Secure login through Devise with multi-factor options
- **Security Features**: Protection via security questions and rate limiting
- **VPN/Proxy Detection**: Maintain platform integrity through traffic monitoring

## Table of Contents

- [Development Environment](#development-environment)
- [Setup Instructions](#setup-instructions)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## Development Environment

### Requirements

- **Ruby**: 3.4.1
- **Rails**: 8.0.1
- **PostgreSQL**: 14.0+
- **Node.js**: 18.0+ (for JavaScript compilation)
- **Yarn**: 1.22+ (for dependency management)
- **Docker & Docker Compose**: (Optional) For containerized development

### Recommended Tools

- **IDE**: Visual Studio Code with Ruby, Rails, and ESLint extensions
- **API Testing**: Postman or Insomnia
- **Database Management**: pgAdmin or TablePlus

## Setup Instructions

### Standard Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/naija-forum.git
   cd naija-forum
   ```

2. **Install dependencies**
   ```bash
   bundle install
   yarn install
   ```

3. **Setup environment variables**
   ```bash
   cp .env.example .env
   # Edit .env file with your local configurations
   ```

4. **Setup the database**
   ```bash
   bin/rails db:create db:migrate
   bin/rails db:seed # Optional: Loads sample data
   ```

5. **Start the development server**
   ```bash
   bin/dev
   ```

6. **Access the application**
   Open your browser and navigate to `http://localhost:3000`

### Docker Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/naija-forum.git
   cd naija-forum
   ```

2. **Build and start the containers**
   ```bash
   docker-compose up --build
   ```

3. **Setup the database (first time only)**
   ```bash
   docker-compose exec web bin/rails db:create db:migrate
   docker-compose exec web bin/rails db:seed # Optional: Loads sample data
   ```

4. **Access the application**
   Open your browser and navigate to `http://localhost:3000`

## Testing

Naija-Forum uses RSpec for testing. The test suite includes unit, integration, and system tests.

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test category
bundle exec rspec spec/models
bundle exec rspec spec/controllers
bundle exec rspec spec/system

# Run a specific test file
bundle exec rspec spec/models/user_spec.rb
```

### Testing with Docker

```bash
docker-compose exec web bundle exec rspec
```

### Code Quality

We use RuboCop for Ruby code linting and ESLint for JavaScript:

```bash
# Ruby linting
bundle exec rubocop

# JavaScript linting
yarn lint
```

## Deployment

### Production Requirements

- Ruby 3.4.1
- PostgreSQL 14.0+
- Redis (for caching and background jobs)
- Nginx (recommended as reverse proxy)
- Systemd or similar for process management

### Deployment Options

#### Heroku Deployment

1. **Create a Heroku application**
   ```bash
   heroku create naija-forum-production
   ```

2. **Add PostgreSQL add-on**
   ```bash
   heroku addons:create heroku-postgresql:hobby-dev
   ```

3. **Configure environment variables**
   ```bash
   heroku config:set RAILS_MASTER_KEY=<your-master-key>
   # Set other necessary environment variables
   ```

4. **Deploy the application**
   ```bash
   git push heroku main
   ```

5. **Run migrations**
   ```bash
   heroku run rails db:migrate
   ```

#### Docker Deployment

1. **Build the production Docker image**
   ```bash
   docker build -t naija-forum:production .
   ```

2. **Run the production container**
   ```bash
   docker run -p 3000:3000 -e RAILS_ENV=production -e DATABASE_URL=<your-db-url> naija-forum:production
   ```

3. **Alternative: Deploy with Docker Compose**
   ```bash
   docker-compose -f docker-compose.production.yml up -d
   ```

## Contributing

We welcome contributions to Naija-Forum! Here's how you can help:

### Getting Started

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards

- Follow the Ruby Style Guide
- Write tests for new features
- Keep methods small and focused
- Document complex logic
- Use meaningful variable and method names

### Pull Request Process

1. Ensure your code passes all tests and linting checks
2. Update the README.md with details of changes if applicable
3. The PR requires approval from at least one maintainer
4. Once approved, a maintainer will merge your changes

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions or support, please open an issue in the GitHub repository or contact the maintainers at support@naija-forum.com
