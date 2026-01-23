# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.2.2
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install runtime packages
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
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_SERVE_STATIC_FILES="1"

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

# Copy gem files and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile Bootsnap cache for app and lib
RUN bundle exec bootsnap precompile app/ lib/

# Precompile Rails assets using a dummy secret key
RUN RAILS_ENV=production SECRET_KEY_BASE=dummy ./bin/rails assets:precompile

FROM base

# Copy gems and app from build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create non-root user and set permissions
RUN groupadd --system --gid 1000 rails && \
    useradd --system --uid 1000 --gid 1000 --create-home --shell /bin/bash rails && \
    chown -R rails:rails db log storage tmp

USER 1000:1000
WORKDIR /rails

EXPOSE 3000
CMD ["bash", "-c", "bin/rails db:prepare && bin/rails server -b '0.0.0.0'"]
