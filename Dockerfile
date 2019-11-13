FROM ruby:2.5
MAINTAINER Ministry of Justice, Track a Query <correspondence@digital.justice.gov.uk>
RUN set -ex

RUN addgroup --gid 1000 --system appgroup && \
    adduser --uid 1000 --system appuser --ingroup appgroup

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

# Set this to any value ("1", "true", etc) to enable development mode.
# e.g. docker build --build-arg development_mode=1 ...
ARG development_mode

RUN echo "development_mode=$development_mode"
RUN bundle config --global frozen 1 && \
    bundle install ${development:+--with="test development"}

COPY . .

RUN mkdir log tmp
RUN chown -R appuser:appgroup /usr/src/app/
USER appuser
USER 1000

RUN RAILS_ENV=production bundle exec rake assets:clean assets:precompile assets:non_digested SECRET_KEY_BASE=required_but_does_not_matter_for_assets 2> /dev/null

RUN chown -R appuser:appgroup ./*
RUN chmod +x /usr/src/app/config/docker/*
