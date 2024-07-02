FROM ruby:3.1.4-alpine
LABEL key="Ministry of Justice, Track a Query <correspondence@digital.justice.gov.uk>"
RUN set -ex

RUN addgroup --gid 1000 --system appgroup && \
    adduser --uid 1000 --system appuser --ingroup appgroup

# Some app dependencies
RUN apk add libreoffice clamav clamav-daemon freshclam ttf-freefont

# Note: .ruby-gemdeps libc-dev gcc libxml2-dev libxslt-dev make  postgresql-dev build-base - these help with bundle install issues
RUN apk add --no-cache --virtual .ruby-gemdeps libc-dev gcc libxml2-dev libxslt-dev make  postgresql-dev build-base git nodejs zip postgresql-client yarn

RUN apk --update add less && apk -U upgrade && apk --no-cache upgrade musl

WORKDIR /usr/src/app/

COPY Gemfile* ./

RUN gem install bundler -v '~> 2.4.19'

RUN bundle config deployment true && \
    bundle config without development test && \
    bundle install --jobs 4 --retry 3

COPY . .

RUN yarn install --pure-lockfile

RUN mkdir -p log tmp tmp/pids
RUN chown -R appuser:appgroup /usr/src/app/
USER appuser
USER 1000

RUN RAILS_ENV=production AWS_ACCESS_KEY_ID=not_real AWS_SECRET_ACCESS_KEY=not_real bundle exec rake assets:clean assets:precompile assets:non_digested SECRET_KEY_BASE=required_but_does_not_matter_for_assets 2> /dev/null

ENV PUMA_PORT 3000
EXPOSE $PUMA_PORT

RUN chown -R appuser:appgroup ./*
RUN chmod +x /usr/src/app/config/docker/*

# expect/add ping environment variables
ARG APP_GIT_COMMIT
ARG APP_BUILD_DATE
ARG APP_BUILD_TAG
ENV APP_GIT_COMMIT=${APP_GIT_COMMIT}
ENV APP_BUILD_DATE=${APP_BUILD_DATE}
ENV APP_BUILD_TAG=${APP_BUILD_TAG}
