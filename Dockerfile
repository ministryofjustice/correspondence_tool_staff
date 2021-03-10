FROM ruby:2.7.2-alpine
LABEL key="Ministry of Justice, Track a Query <correspondence@digital.justice.gov.uk>"
RUN set -ex

RUN addgroup --gid 1000 --system appgroup && \
    adduser --uid 1000 --system appuser --ingroup appgroup

WORKDIR /usr/src/app/

RUN apk -U upgrade
RUN apk add git

COPY Gemfile* ./

RUN apk add --no-cache --virtual .ruby-gemdeps libc-dev gcc libxml2-dev libxslt-dev make  postgresql-dev build-base

#RUN gem install bundler -v '~> 2.2.13'

RUN bundle config set --global frozen 1 && \
    bundle config set without 'development test' && \
    bundle install  



