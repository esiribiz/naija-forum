# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.2.2
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Install runtime packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl wget libjemalloc2 libvips postgresql-client nodejs yarn && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Set environment variables
ENV RAILS_ENV="production" \
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
      build-essential libpq-dev libffi-dev pkg-config git nodejs yarn && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Copy gem files & install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Precompile bootsnap for faster boot
RUN bundle exec bootsnap precompile --gemfile

# Copy full app source
COPY . .

# Rails 8+ requires a real secret key
ARG SECRET_KEY_BASE
RUN RAILS_ENV=production SECRET_KEY_BASE=$SECRET_KEY_BASE ./bin/rails assets:precompile

# ----------------------------
# Final runtime stage
# ----------------------------
FROM base

# Copy gems & app from build stage
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER 1000:1000

EXPOSE 3000

# Entrypoint
CMD ["bash", "-c", "bin/rails db:prepare && bin/rails server -b '0.0.0.0'"]
