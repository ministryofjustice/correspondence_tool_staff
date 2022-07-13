FROM ruby:2.7.2-alpine
LABEL key="Ministry of Justice, Track a Query <correspondence@digital.justice.gov.uk>"
RUN set -ex

RUN addgroup --gid 1000 --system appgroup && \
    adduser --uid 1000 --system appuser --ingroup appgroup

# Some app dependencies
RUN apk add libreoffice clamav clamav-daemon freshclam ttf-ubuntu-font-family

# Note: .ruby-gemdeps libc-dev gcc libxml2-dev libxslt-dev make  postgresql-dev build-base - these help with bundle install issues
RUN apk add --no-cache --virtual .ruby-gemdeps libc-dev gcc libxml2-dev libxslt-dev make  postgresql-dev build-base git nodejs zip postgresql-client

RUN apk --update add less && apk -U upgrade && apk --no-cache upgrade musl

WORKDIR /usr/src/app/

COPY Gemfile* ./

RUN gem install bundler -v '~> 2.2.13'

RUN bundle config set --global frozen 1 && \
    bundle config set without 'development test' && \
    bundle install  

COPY . .

RUN mkdir log tmp
RUN chown -R appuser:appgroup /usr/src/app/
USER appuser
USER 1000

RUN RAILS_ENV=production AWS_ACCESS_KEY_ID=not_real AWS_SECRET_ACCESS_KEY=not_real bundle exec rake assets:clean assets:precompile assets:non_digested SECRET_KEY_BASE=required_but_does_not_matter_for_assets 2> /dev/null

ENV PUMA_PORT 3000
EXPOSE $PUMA_PORT

RUN chown -R appuser:appgroup ./*
RUN chmod +x /usr/src/app/config/docker/*

# expect/add ping environment variables
ARG VERSION_NUMBER
ARG COMMIT_ID
ARG BUILD_DATE
ARG BUILD_TAG
ENV VERSION_NUMBER=${VERSION_NUMBER}
ENV APP_GIT_COMMIT=${COMMIT_ID}
ENV APP_BUILD_DATE=${BUILD_DATE}
ENV APP_BUILD_TAG=${BUILD_TAG}
