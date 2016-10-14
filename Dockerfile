FROM ministryofjustice/ruby:2.3.1-webapp-onbuild

ENV PUMA_PORT 3000

RUN touch /etc/inittab

RUN apt-get update && apt-get install -y

EXPOSE $PUMA_PORT

RUN bundle exec rake assets:precompile RAILS_ENV=production \
  SECRET_KEY_BASE=required_but_does_not_matter_for_assets

ENTRYPOINT ["./run.sh"]