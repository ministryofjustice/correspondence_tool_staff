FROM ruby:2.3

WORKDIR /usr/src/app

# RUN touch /etc/inittab

ENV PUMA_PORT 3000

EXPOSE $PUMA_PORT

RUN apt-get update && apt-get install -y apt-transport-https && \
    rm -rf /var/lib/apt/lists/*

# add official nodejs repo
RUN . /etc/os-release ; release="${VERSION#* (}" ; release="${release%)}" ; \
    curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo "deb https://deb.nodesource.com/node $release main" > /etc/apt/sources.list.d/nodesource.list

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL repo to sources
RUN . /etc/os-release ; release="${VERSION#* (}" ; release="${release%)}" ; \
    echo "deb https://apt.postgresql.org/pub/repos/apt/ $release-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Use this to add to the list of packages installed into an image. For example,
# the uploads image should also have clamav, clamav-daemon and libreoffice
# installed. Use this by specifying --build-arg with docker build:
#
#   docker build --build-args additional_pacakges='clamav clamav-daemon freshclam libreoffice'
#
# Or by adding build args to the docker-compose file.
ARG additional_packages

RUN apt-get update && apt-get install -y less \
                                         nodejs \
                                         runit \
                                         postgresql-client-9.5 \
                                         $additional_packages && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./

# Set this to any value ("1", "true", etc) to enable development mode.
# e.g. docker build --build-arg development_mode=1 ...
ARG development_mode

RUN echo "development_mode=$development_mode"

RUN bundle config --global frozen 1 \
    && ( [ -z "$development" ] \
         && bundle config --global without test:development ) || true \
    && bundle install

COPY . .

RUN mkdir log tmp

RUN bundle exec rake assets:precompile assets:non_digested SECRET_KEY_BASE=required_but_does_not_matter_for_assets

ENTRYPOINT ["./run.sh"]
