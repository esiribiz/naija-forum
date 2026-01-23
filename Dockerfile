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
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set default environment variables by reference only (do not hardcode sensitive values)
ENV BUNDLE_DEPLOYMENT="${BUNDLE_DEPLOYMENT}" \
    BUNDLE_PATH="${BUNDLE_PATH}" \
    RAILS_ENV="${RAILS_ENV}"


# ----------------------------
# Build stage
# ----------------------------
FROM base AS build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libffi-dev libpq-dev libyaml-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Configure Bundler properly for production gems
RUN bundle config set without 'development test'

# Copy gem files & install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy app code
COPY . .

# Precompile bootsnap for faster boot
RUN bundle exec bootsnap precompile app/ lib/

# Precompile Rails assets without requiring master key
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# ----------------------------
# Final runtime stage
# ----------------------------
FROM base

# Install runtime packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y imagemagick libvips && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy gems & app from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Create non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R 1000:1000 db log storage tmp

USER 1000:1000

# Entrypoint
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
