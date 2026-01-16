FROM ruby:3.3.6-alpine AS base

RUN set -ex
RUN apk update
RUN apk add libreoffice
RUN apk add --no-cache --virtual .ruby-gemdeps libc-dev gcc libxml2-dev libxslt-dev make postgresql-dev build-base git nodejs npm zip postgresql-client
RUN apk --update add less && apk -U upgrade && apk --no-cache upgrade musl

# add non-root user and group with first available uid, 1000
RUN addgroup --gid 1000 --system appgroup && \
    adduser --uid 1000 --system appuser --ingroup appgroup


FROM base AS dev

RUN mkdir -p /usr/src/app
ADD . /usr/src/app/
WORKDIR /usr/src/app/

RUN gem install bundler -v '~> 2.4.19'
RUN bundle config --global frozen 1

RUN mkdir log tmp && touch /usr/src/app/log/lograge_development.log
RUN mkdir tmp/pids

# Add a script to be executed every time the container starts.
COPY config/docker-dev/bin/*.sh /usr/bin/
RUN chmod +x /usr/bin/*

ENV PUMA_PORT 3030
EXPOSE $PUMA_PORT

# expect/add ping environment variables
ARG VERSION_NUMBER
ARG COMMIT_ID
ARG BUILD_DATE
ARG BUILD_TAG
ENV APP_VERSION=${VERSION_NUMBER}
ENV APP_GIT_COMMIT=${COMMIT_ID}
ENV APP_BUILD_DATE=${BUILD_DATE}
ENV APP_BUILD_TAG=${BUILD_TAG}
