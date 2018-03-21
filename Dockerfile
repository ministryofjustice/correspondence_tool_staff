FROM registry.service.dsd.io/correspondence-staff-app

ENV PUMA_PORT 3000
ENV RAILS_ENV=production

EXPOSE $PUMA_PORT

RUN bundle exec rake assets:precompile assets:non_digested \
      SECRET_KEY_BASE=required_but_does_not_matter_for_assets

ENTRYPOINT ["./run.sh"]
