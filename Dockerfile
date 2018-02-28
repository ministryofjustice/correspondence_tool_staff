FROM registry.service.dsd.io/correspondence-staff-base

ENV PUMA_PORT 3000

RUN touch /etc/inittab

EXPOSE $PUMA_PORT

RUN bundle exec rake assets:precompile assets:non_digested RAILS_ENV=production \
  SECRET_KEY_BASE=required_but_does_not_matter_for_assets

ENTRYPOINT ["./run.sh"]
