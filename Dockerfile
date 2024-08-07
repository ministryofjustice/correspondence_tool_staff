FROM ruby:3.1.4-alpine as builder

WORKDIR /app

# Some app dependencies
RUN apk --no-cache add \
    build-base \
    ruby-dev \
    postgresql-dev \
    git \
    yarn

COPY .ruby-version Gemfile* package.json yarn.lock ./

# Install gems and node packages
RUN bundle config deployment true && \
    bundle config without development test && \
    bundle install --jobs 4 --retry 3 && \
    yarn install --frozen-lockfile --production

COPY . .

RUN RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 \
    bundle exec rake assets:precompile

# Cleanup to save space in the production image
RUN rm -rf node_modules log/* tmp/* /tmp && \
    rm -rf /usr/local/bundle/cache

# Build runtime image
FROM ruby:3.1.4-alpine

# The application runs from /app
WORKDIR /app

# zip: needed for creating reports
RUN apk --no-cache add \
    nodejs \
    postgresql-client \
    zip

RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

# Copy files generated in the builder image
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

RUN mkdir -p log tmp tmp/pids
RUN chown -R appuser:appgroup /app

USER 1000

# expect/add ping environment variables
ARG APP_GIT_COMMIT
ARG APP_BUILD_DATE
ARG APP_BUILD_TAG
ENV APP_GIT_COMMIT=${APP_GIT_COMMIT}
ENV APP_BUILD_DATE=${APP_BUILD_DATE}
ENV APP_BUILD_TAG=${APP_BUILD_TAG}
