# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.1
FROM ruby:$RUBY_VERSION-slim AS base

LABEL fly_launch_runtime="rails"

WORKDIR /rails

# Update gems & install bundler
RUN gem update --system --no-document && \
    gem install -N bundler

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        curl \
        libjemalloc2 \
        libvips \
        postgresql-client \
        imagemagick \
        build-essential \
        libffi-dev \
        libpq-dev \
        libyaml-dev && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# ----------------------------
# Build stage
# ----------------------------
FROM base AS build

# Set Bundler environment variables for reproducible install
ENV BUNDLE_PATH=/rails/vendor/bundle \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_DEPLOYMENT=true

# Copy gem files & install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# Precompile bootsnap for faster boot
RUN bundle exec bootsnap precompile --gemfile

# Copy app code
COPY . .

# Precompile bootsnap for app directories
RUN bundle exec bootsnap precompile app/ lib/

# Precompile Rails assets without master key
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ----------------------------
# Final runtime stage
# ----------------------------
FROM base AS runtime

# Set runtime environment variables
ENV BUNDLE_PATH=/rails/vendor/bundle \
    RAILS_ENV=production \
    RACK_ENV=production

# Copy gems & app from build stage
COPY --from=build /rails/vendor/bundle /rails/vendor/bundle
COPY --from=build /rails /rails

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd --system --uid 1000 --gid 1000 --create-home --shell /bin/bash rails && \
    chown -R 1000:1000 db log storage tmp

USER 1000:1000

WORKDIR /rails

# Entrypoint
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Expose port 80
EXPOSE 80

# Default command
CMD ["./bin/thrust", "./bin/rails", "server"]
