FROM ruby:2.5.8
MAINTAINER Ministry of Justice, Track a Query <correspondence@digital.justice.gov.uk>
RUN set -ex

RUN addgroup --gid 1000 --system appgroup && \
    adduser --uid 1000 --system appuser --ingroup appgroup

# expect/add ping environment variables
ARG VERSION_NUMBER
ARG COMMIT_ID
ARG BUILD_DATE
ARG BUILD_TAG
ENV VERSION_NUMBER=${VERSION_NUMBER}
ENV APP_GIT_COMMIT=${COMMIT_ID}
ENV APP_BUILD_DATE=${BUILD_DATE}
ENV APP_BUILD_TAG=${BUILD_TAG}

WORKDIR /usr/src/app/

ENV PUMA_PORT 3000
EXPOSE $PUMA_PORT

RUN apt-get update && \
    apt-get install -y apt-transport-https && \
    rm -rf /var/lib/apt/lists/*

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --batch --no-tty --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL repo to sources
RUN . /etc/os-release ; release="${VERSION#* (}" ; release="${release%)}" ; \
    echo "deb https://apt.postgresql.org/pub/repos/apt/ $release-pgdg main" > /etc/apt/sources.list.d/pgdg.list

RUN echo "Installing libraries..."
RUN apt-get update && \
    apt-get install -y less \
    nodejs \
    runit \
    postgresql-client-9.5 \
    zip \
    libreoffice \
    clamav \
    clamav-daemon \
    clamav-freshclam

# ENV RAILS_ENV='production'
COPY Gemfile* ./

RUN bundle config --global frozen 1 && \
    bundle install 

COPY . .

RUN mkdir log tmp
RUN chown -R appuser:appgroup /usr/src/app/
USER appuser
USER 1000

RUN RAILS_ENV=production bundle exec rake assets:clean assets:precompile assets:non_digested SECRET_KEY_BASE=required_but_does_not_matter_for_assets 2> /dev/null

RUN chown -R appuser:appgroup ./*
RUN chmod +x /usr/src/app/config/docker/*
