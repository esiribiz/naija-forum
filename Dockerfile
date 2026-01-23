# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.1
FROM ruby:$RUBY_VERSION-slim AS base

LABEL fly_launch_runtime="rails"

WORKDIR /rails

# Update RubyGems & install bundler
RUN gem update --system --no-document && \
    gem install --no-document bundler

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# ----------------------------
# Build stage
# ----------------------------
FROM base AS build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libffi-dev libpq-dev libyaml-dev && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Configure Bundler for production
RUN bundle config set --local path 'vendor/bundle' && \
    bundle config set without 'development test'

# Copy gem files & install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle && \
    bundle exec bootsnap precompile --gemfile

# Copy app code
COPY . .

# Precompile bootsnap for app directories
RUN bundle exec bootsnap precompile app/ lib/

# Precompile Rails assets without master key
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ----------------------------
# Final runtime stage
# ----------------------------
FROM base

# Install runtime packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y imagemagick libvips && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Copy gems & app from build stage
COPY --from=build /rails/vendor/bundle /rails/vendor/bundle
COPY --from=build /rails /rails

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd --system --uid 1000 --gid 1000 --create-home --shell /bin/bash rails && \
    chown -R 1000:1000 /rails/db /rails/log /rails/storage /rails/tmp

USER 1000:1000

# Entrypoint
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
