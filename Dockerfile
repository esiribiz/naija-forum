# syntax=docker/dockerfile:1

# ----------------------------
# Base image
# ----------------------------
ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION-slim AS base

LABEL maintainer="your-email@example.com"
WORKDIR /rails

# Install essential packages for runtime
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        curl \
        wget \
        libjemalloc2 \
        libvips \
        postgresql-client \
        imagemagick \
        tzdata && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Set environment variables
ENV RAILS_ENV="production" \
    RACK_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_SERVE_STATIC_FILES="1"

# ----------------------------
# Build stage
# ----------------------------
FROM base AS build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        build-essential \
        git \
        libpq-dev \
        pkg-config \
        nodejs \
        yarn \
        ruby-dev \
        libxml2-dev \
        libxslt1-dev \
        libcurl4-openssl-dev && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Copy Gemfiles and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile Bootsnap cache for app directories
RUN bundle exec bootsnap precompile app/ lib/

# Precompile Rails assets with dummy key for production build
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production ./bin/rails assets:precompile

# ----------------------------
# Runtime stage
# ----------------------------
FROM base AS runtime

# Copy gems and app from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd --system --uid 1000 --gid 1000 --create-home --shell /bin/bash rails && \
    chown -R rails:rails db log storage tmp

USER 1000:1000
WORKDIR /rails

# Expose port
EXPOSE 3000

# Entrypoint and default command
ENTRYPOINT ["./bin/docker-entrypoint"]
CMD ["bash", "-c", "bin/rails db:prepare && bin/rails server -b '0.0.0.0'"]
