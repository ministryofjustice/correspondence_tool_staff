FROM ruby:2.5

RUN addgroup --gid 1000 --system appgroup && \
    adduser --uid 1000 --system appuser --ingroup appgroup


WORKDIR /usr/src/app/


ENV PUMA_PORT 3000

EXPOSE $PUMA_PORT

RUN apt-get update && apt-get install -y apt-transport-https && \
    rm -rf /var/lib/apt/lists/*

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --batch --no-tty --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Add PostgreSQL repo to sources
RUN . /etc/os-release ; release="${VERSION#* (}" ; release="${release%)}" ; \
    echo "deb https://apt.postgresql.org/pub/repos/apt/ $release-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Use this to add to the list of packages installed into an image. For example,
# the uploads image should also have clamav, clamav-daemon and libreoffice
# installed. Use this by specifying --build-arg with docker build:
#
#   docker build --build-args additional_pacakges='clamav clamav-daemon clamav-freshclam libreoffice'
#
# Or by adding build args to the docker-compose file.


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
    && bundle install ${development:+--with="test development"}

COPY . .

RUN mkdir log tmp


RUN echo "Giving User permission..."
RUN chown -R appuser:appgroup /usr/src/app/
USER appuser
RUN echo "=+=====++ ====== = == = = == ========="
RUN mkdir fake-dir
RUN pwd
RUN ls -al
RUN echo "=+=====++ ====== = == = = == ========="
USER 1000

RUN echo "RUNNING ASSET PIPELINE COMPILATION..."
RUN chown -R appuser:appgroup ./*
RUN ls -al
RUN RAILS_ENV=production bundle exec rake assets:clean assets:precompile assets:non_digested SECRET_KEY_BASE=required_but_does_not_matter_for_assets

#RUN echo "SETTING ENVIRONMENT VARIABLES..."
#
## RDS New Staging (London)
#ENV DATABASE_URL=postgres://cp4gmTcfOW:syFpKbswUCOTOmBq@cloud-platform-6d3055284f4c1f39.cdwm328dlye6.eu-west-2.rds.amazonaws.com:5432/db6d3055284f4c1f39
#ENV DB_ENGINE=postgres
#ENV DB_HOST=cloud-platform-6d3055284f4c1f39.cdwm328dlye6.eu-west-2.rds.amazonaws.com
#ENV DB_NAME=db6d3055284f4c1f39
#ENV DB_PASSWORD=syFpKbswUCOTOmBq
#ENV DB_PORT=5432
#ENV DB_USERNAME=cp4gmTcfOW
#ENV ENV=prod
#ENV PROJECT=correspondence-staff
#ENV RAILS_ENV=production
#
## Current DEV environment Redis server
#ENV REDIS_HOST=coe10oxlc36q590d.eq1onc.ng.0001.euw1.cache.amazonaws.com
#ENV REDIS_PORT=6379
#ENV REDIS_URL=redis://coe10oxlc36q590d.eq1onc.ng.0001.euw1.cache.amazonaws.com:6379
#
## Current DEV app settings
#ENV SECRET_KEY_BASE=60ae086f3a7a0e43804d411ff59dad6bc785686e2b981bde9b82368600df83635bb83bcf9f8c1cda6322f0f7e3a44794dfb84899a0cd4b1b4bfe1c8c5e285eff
#ENV SETTINGS__CASE_UPLOADS_S3_BUCKET=correspondence-staff-case-uploads-dev
#ENV SETTINGS__CTS_EMAIL_URL=https://dev.track-a-query.service.justice.gov.uk
#ENV SETTINGS__GOVUK_NOTIFY_API_KEY=trackaquery_development-ec94811d-117a-4f52-8d3a-e4272089dc32-6eb3a617-465b-441e-b886-4be0d1b44084
#ENV SETTINGS__SMOKE_TESTS__PASSWORD=Go239@4jB9TbS3k$ZgDmQI!X8eW0R72^
#ENV SETTINGS__SMOKE_TESTS__USERNAME=correspondence-staff-dev+smoke.tests@digital.justice.gov.uk


ENTRYPOINT ["./run.sh"]
