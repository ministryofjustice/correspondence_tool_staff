FROM ministryofjustice/ruby:2.3.1-webapp-onbuild

ENV PUMA_PORT 3000

RUN touch /etc/inittab

RUN apt-get update -y  && \
    apt-get install wget ca-certificates lsb-release  && \
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -  && \
    apt-get update && \
    apt-get install -y postgresql-client-9.5

EXPOSE $PUMA_PORT

RUN bundle exec rake assets:precompile RAILS_ENV=production \
  SECRET_KEY_BASE=required_but_does_not_matter_for_assets

ENTRYPOINT ["./run.sh"]