ARG RUBY_VERSION=3
FROM ruby:${RUBY_VERSION}-slim AS base

# create a nonroot user
RUN useradd -m nonroot

WORKDIR /app

# install system dependencies
RUN apt-get -qq update && apt-get --no-install-recommends install -y build-essential git && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# set the BUNDLE_APP_CONFIG environment variable
ENV BUNDLE_APP_CONFIG=/app/.bundle

# copy bundler config
COPY --chown=nonroot:nonroot .bundle ./.bundle

# install core scripts
COPY --chown=nonroot:nonroot script ./script

# copy core ruby files first
COPY --chown=nonroot:nonroot .ruby-version Gemfile Gemfile.lock ./

# copy vendored gems
COPY --chown=nonroot:nonroot vendor/cache ./vendor/cache

# create the ./bin directory
RUN mkdir -p ./bin

# bootstrap the ruby environment
RUN script/bootstrap --production

# copy the rest of the application
COPY --chown=nonroot:nonroot . .

# change ownership of /app directory to nonroot user
RUN chown -R nonroot:nonroot /app

# switch to the nonroot user
USER nonroot
